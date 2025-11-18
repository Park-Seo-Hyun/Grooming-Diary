from transformers import AutoTokenizer, AutoModelForCausalLM
import torch
import torch.nn.functional as F
import os

## KoGPT2 공감 모델의 파라미터 및 설정 적용
MODEL_NAME = "dlckdfuf141/empathy-kogpt2"
MAX_NEW_TOKENS = 60 
TEMPERATURE = 0.8
TOP_P = 0.95

## 모델 및 토크나이저 로드 (서버 시작 시 1회 로드)
try:
    tokenizer = AutoTokenizer.from_pretrained(MODEL_NAME)
    ## CPU/GPU 자동 감지 및 로드 (cuda 사용이 불가능하면 cpu로 대체)
    DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    ## KoGPT2는 pad_token이 없으므로, eos_token을 pad_token으로 설정하여 안정성 확보
    tokenizer.pad_token = tokenizer.eos_token 
    
    ## 모델을 DEVICE에 로드
    model = AutoModelForCausalLM.from_pretrained(MODEL_NAME).to(DEVICE)
    print(f"INFO: KoGPT-2 Empathy model loaded successfully on {DEVICE}.")
except Exception as e:
    print(f"ERROR: Failed to load KoGPT-2 Empathy model: {e}")
    ## 모델 로딩 실패 시 더미 함수로 대체하여 서버는 계속 작동하도록 함
    def tokenizer(*args, **kwargs): return {}
    def model(*args, **kwargs): pass
    DEVICE = "cpu"

def generate_comment(content: str, emotion_label: str) -> str:
    """
    사용자의 일기 내용과 감정 레이블을 기반으로 공감 메시지를 생성합니다.
    (따뜻한 심리 상담가 페르소나를 부여)
    """
    
    # 🌟 페르소나 및 지시사항 추가 (프롬프트 구성)
    system_instruction = (
        "당신은 따뜻하고 공감 능력이 뛰어난 심리 상담가입니다. "
        "사용자의 일기를 보고, 50자 이내의 짧고 격려가 되는 친구가 보내는 듯한 공감 메시지를 한국어로 작성하세요."
    )
    
    # KoGPT2 모델 프롬프트 형식: [지시사항]\n\n감정: {emotion_label}\n일기: {content}\n공감 메시지:
    prompt = f"{system_instruction}\n\n감정: {emotion_label}\n일기: {content}\n공감 메시지:"
    
    try:
        # return_tensors="pt" 사용
        inputs = tokenizer(prompt, return_tensors="pt").to(DEVICE)

        ## 모델 추론
        with torch.no_grad():
            outputs = model.generate(
                **inputs,
                max_new_tokens=MAX_NEW_TOKENS,
                do_sample=True,
                top_p=TOP_P,
                temperature=TEMPERATURE,
                pad_token_id=tokenizer.pad_token_id,
                eos_token_id=tokenizer.eos_token_id,
                num_return_sequences=1
            )
        
        # 결과 디코딩 및 응답 파싱
        generated_text = tokenizer.decode(outputs[0], skip_special_tokens=True)
        
        # "공감 메시지:" 이후의 텍스트만 추출
        response = generated_text.split("공감 메시지:")[-1].strip()
        
        # 불필요한 프롬프트 잔여물 제거 및 길이 제한 적용
        if len(response) > 50:
            return response[:50].strip() + "..."
        
        return response

    except Exception as e:
        print(f"ERROR during comment generation: {e}")
        # AI 모델 호출 실패 시, 라우터에서 설정한 기본 실패 메시지를 사용하도록 예외를 다시 발생시킴
        raise Exception(f"AI 코멘트 생성 중 예외 발생: {e}")