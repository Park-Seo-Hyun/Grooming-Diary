from transformers import AutoTokenizer, AutoModelForCausalLM
import torch
import torch.nn.functional as F
import os
from typing import Dict, Any

## ⚠️ FINAL FIX: 파인튜닝된 모델의 로컬 경로를 지정합니다.
# 이 경로를 Google Drive 동기화된 모델 폴더의 실제 로컬 경로로 변경해야 합니다.
# 예시: D:/MyDrive/Grooming/backend/ai_model/fine_tuned_kogpt2_model
LOCAL_MODEL_PATH = "D:/Grooming/backend/ai_model/fine_tuned_kogpt2_model" 

# 🌟 사용자의 요청에 따라 'Tender'를 '행복'으로 매핑하여 수정함 🌟
EMOTION_ENG_TO_KOR: Dict[str, str] = {
    "Angry": "분노",
    "Fear": "공포",
    "Sad": "슬픔",
    "Happy": "행복",
    "Tender": "행복",  # 요청에 따라 '부드러움' 대신 '행복'으로 설정
    "Neutral": "중립"
}

# -------------------------- 모델 및 토크나이저 로드 (서버 시작 시 1회 로드) --------------------------
LOAD_SUCCESS = False
try:
    # ⚠️ FIX: 모델 로드 경로를 로컬 파인튜닝 모델 경로로 변경합니다.
    tokenizer = AutoTokenizer.from_pretrained(LOCAL_MODEL_PATH)
    
    # ⚠️ CPU로 강제 지정 (노트북 환경 안정화)
    DEVICE = torch.device("cpu")
    
    tokenizer.pad_token = tokenizer.eos_token 
    
    ## 모델을 DEVICE에 로드
    model = AutoModelForCausalLM.from_pretrained(LOCAL_MODEL_PATH).to(DEVICE)
    model.eval() # 추론 모드로 설정
    
    print(f"INFO: KoGPT-2 Empathy model loaded successfully from local path on {DEVICE}.")
    LOAD_SUCCESS = True
except Exception as e:
    print(f"ERROR: Failed to load KoGPT-2 Empathy model from {LOCAL_MODEL_PATH}. Error: {e}")
    # 모델 로딩 실패 시 더미 함수로 대체하여 서버는 계속 작동하도록 함
    def tokenizer(*args, **kwargs): 
        # 더미 토크나이저를 사용하기 위해 BASE_MODEL_ID 토크나이저를 임시 로드 (필수)
        try:
            temp_tokenizer = AutoTokenizer.from_pretrained("dlckdfuf141/empathy-kogpt2")
            return temp_tokenizer(*args, **kwargs)
        except Exception:
            return {'input_ids': torch.tensor([[101, 102]]), 'attention_mask': torch.tensor([[1, 1]])}
    
    class DummyModel:
        def generate(self, input_ids, **kwargs):
            dummy_text = "모델 로드 실패. 죄송합니다."
            try:
                temp_tokenizer = AutoTokenizer.from_pretrained("dlckdfuf141/empathy-kogpt2")
                dummy_output = temp_tokenizer(dummy_text, return_tensors="pt").input_ids
                return dummy_output
            except Exception:
                return torch.tensor([[101, 102]])

        def to(self, device): return self
        def eval(self): pass

    model = DummyModel()
    DEVICE = "cpu"
    LOAD_SUCCESS = False


def generate_comment(content: str, emotion_label: str) -> str:
    """
    사용자의 일기 내용과 감정 레이블을 바탕으로 파인튜닝된 모델로 공감 메시지를 생성합니다.
    친한 친구처럼 반말을 사용하며, 응답 품질을 개선했습니다.
    """
    # ⚠️ 모델 로드 실패 시, 기본 에러 메시지를 반환하여 서버 다운을 방지합니다.
    if not LOAD_SUCCESS:
        return "현재 AI 챗봇 모델 로딩에 실패했습니다. 관리자에게 문의하세요."
        
    korean_emotion = EMOTION_ENG_TO_KOR.get(emotion_label, "중립")
    
    # 🌟 FIX: 반복/잔여물 출력을 막기 위해 프롬프트에 금지 단어를 명시적으로 추가
    prompt = (
        f"당신은 사용자의 이야기를 경청하고 공감하는 따뜻하고 정중한 상담가입니다. 지금부터 사용자에게 **존댓말(하십시오체)**만을 사용해 답변하십시오. "
        f"사용자의 **{korean_emotion} 감정만을 언급하며** 일기 내용에 진심으로 공감하고, 해당 감정에 맞추어 정중하게 위로와 조언을 드립니다. " # FIX: 감정 언급 지시 강화
        f"응답은 일기 내용에만 관련되게 작성하고, '어떤:', '반응은', '틱으로', '분노', '슬픔', '공포' 등의 다른 감정 단어는 절대 언급하지 마십시오.\n\n" # FIX: 금지 단어 목록에 다른 부정 감정 추가
        f"일기 내용: {content}\n"
        f"상담가의 응답:" 
    )
    
    try:
        # return_tensors="pt" 사용
        inputs = tokenizer(prompt, return_tensors="pt").to(DEVICE)
        
        # ⚠️ FIX: Max Token 값을 50으로 증가시켜 문장 완성도를 높임. (사용자 요청: 최대 200자 목표)
        MAX_NEW_TOKENS = 100 # 200자 생성을 위해 토큰 수를 100으로 증가
        TEMPERATURE = 0.7
        TOP_P = 0.95
        
        with torch.no_grad():
            outputs = model.generate(
                inputs.input_ids,
                # 🌟 FIX: attention_mask를 명시적으로 전달하여 경고 해결
                attention_mask=inputs.attention_mask,
                max_new_tokens=MAX_NEW_TOKENS,
                do_sample=True,
                top_p=TOP_P,
                temperature=TEMPERATURE,
                pad_token_id=tokenizer.pad_token_id,
                eos_token_id=tokenizer.eos_token_id,
                num_return_sequences=1
            )
        
        # 결과 디코딩
        generated_text = tokenizer.decode(outputs[0], skip_special_tokens=True)
        
        # 🌟 FIX: 응답 파싱을 '친구의 반응:' 이후의 텍스트만 추출하도록 수정
        response = generated_text.split("친구의 반응:")[-1].strip()
        
        # 불필요한 프롬프트 잔여물 및 모델이 반복한 내용 제거 후처리
        # 1. 일기 내용이 다시 나타나면 그 앞부분만 사용
        if "일기 내용:" in response:
            response = response.split("일기 내용:")[0].strip()
            
        # 2. 잔여 프롬프트 제거 (이전 오류 패턴 포함)
        if "사용자님의 답변을 듣고 어떤" in response:
            return "에이, 기운 내 친구야! 너의 이야기를 들어줄게."
            
        # 3. 줄바꿈 문자로 인해 문장이 끊기는 경우 첫 줄만 사용
        if "\n" in response:
            response = response.split("\n")[0].strip()
        
        # 4. 길이 제한 적용 (200자 초과 시 ... 추가)
        if len(response) > 200:
            return response[:200].strip() + "..."
            
        return response

    except Exception as e:
        print(f"ERROR during comment generation: {e}")
        # AI 모델 호출 실패 시, 기본 실패 메시지를 반환
        return "야, 미안! 지금 AI 친구가 잠깐 정신을 놨어. 다시 한번 시도해볼게." # 친구 컨셉에 맞게 변경