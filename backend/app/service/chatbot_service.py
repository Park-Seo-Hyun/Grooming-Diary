from transformers import AutoTokenizer, AutoModelForCausalLM
import torch
import torch.nn.functional as F
import os
from typing import Dict, Any

## ⚠️ FINAL FIX: 파인튜닝된 모델의 로컬 경로를 지정합니다.
LOCAL_MODEL_PATH = r"D:/Grooming/backend/app/ai_model/fine_tuned_kogpt2_model" 

# 🌟 사용자의 요청에 따라 'Tender'를 '행복'으로 매핑하여 수정함 🌟
EMOTION_ENG_TO_KOR: Dict[str, str] = {
    "Angry": "분노",
    "Fear": "공포",
    "Sad": "슬픔",
    "Happy": "행복",
    "Tender": "행복",
    "Neutral": "중립"
}

# -------------------------- 모델 및 토크나이저 로드 --------------------------
LOAD_SUCCESS = False
try:
    tokenizer = AutoTokenizer.from_pretrained(LOCAL_MODEL_PATH)

    DEVICE = torch.device("cpu")
    tokenizer.pad_token = tokenizer.eos_token 
    
    model = AutoModelForCausalLM.from_pretrained(LOCAL_MODEL_PATH).to(DEVICE)
    model.eval()
    
    print(f"INFO: KoGPT-2 Empathy model loaded successfully from local path on {DEVICE}.")
    LOAD_SUCCESS = True

except Exception as e:
    print(f"ERROR: Failed to load KoGPT-2 Empathy model from {LOCAL_MODEL_PATH}. Error: {e}")

    def tokenizer(*args, **kwargs):
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
    if not LOAD_SUCCESS:
        return "현재 AI 챗봇 모델 로딩에 실패했습니다. 관리자에게 문의하세요."
        
    korean_emotion = EMOTION_ENG_TO_KOR.get(emotion_label, "중립")
    
    prompt = (
        f"감정: {korean_emotion}\n"
        f"일기: {content}\n"
        f"공감 메시지: "
    )
    
    try:
        inputs = tokenizer(prompt, return_tensors="pt").to(DEVICE)
        
        MAX_NEW_TOKENS = 100
        TEMPERATURE = 0.7
        TOP_P = 0.95
        
        with torch.no_grad():
            outputs = model.generate(
                inputs.input_ids,
                attention_mask=inputs.attention_mask,
                max_new_tokens=MAX_NEW_TOKENS,
                do_sample=True,
                top_p=TOP_P,
                temperature=TEMPERATURE,
                pad_token_id=tokenizer.pad_token_id,
                eos_token_id=tokenizer.eos_token_id,
                num_return_sequences=1
            )
        
        generated_text = tokenizer.decode(outputs[0], skip_special_tokens=True)
        
        # -------------------------------------------------------
        # 🌟 FIX HERE: "친구의 반응:" → "공감 메시지:" 로 변경
        # -------------------------------------------------------
        response = generated_text.split("공감 메시지:")[-1].strip()
        # -------------------------------------------------------

        # 불필요한 프롬프트 잔여물 제거
        if "일기 내용:" in response:
            response = response.split("일기 내용:")[0].strip()
            
        if "사용자님의 답변을 듣고 어떤" in response:
            return "에이, 기운 내 친구야! 너의 이야기를 들어줄게."
            
        if "\n" in response:
            response = response.split("\n")[0].strip()
        
        if len(response) > 197:
            return response[:197].strip() + "..."
            
        return response

    except Exception as e:
        print(f"ERROR during comment generation: {e}")
        return "야, 미안! 지금 AI 친구가 잠깐 정신을 놨어. 다시 한번 시도해볼게."
