#backend/app/service/chatbot_service.py

from transformers import AutoTokenizer, AutoModelForCausalLM
import torch
import torch.nn.functional as F
import os

MAX_LENGTH = 512
TEMPERATURE = 0.7
MODEL_NAME = "byeolki/Llama-KoEmpathy"
## AI 코멘트 길이 제한
MAX_OUTPUT_TOKENS = 50 
## 사용자 입력 길이 제한
MAX_INPUT_CHARS = 100

## 모델 및 토크나이저 로드
try:
    tokenizer = AutoTokenizer.from_pretrained(MODEL_NAME)
    model = AutoModelForCausalLM.from_pretrained(MODEL_NAME)
    DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    model.to(DEVICE)
    print(f"INFO: Llama model loaded successfully on {DEVICE}.")
except Exception as e:
    print(f"ERROR: Failed to load Llama model: {e}")
    ## 모델 로딩 실패 시 더미 함수를 사용하여 서버는 계속 작동하도록 한다.
    def tokenizer(*args, **kwargs): return {}
    def model(*args, **kwargs): pass
    DEVICE = "cpu"

def generate_comment(content: str, emotion_label: str) -> str:
    
    safe_text = content[:MAX_INPUT_CHARS]
    
    # 챗봇의 페르소나와 지시사항 정의
    system_instruction = (
        "당신은 따뜻하고 공감 능력이 뛰어난 심리 상담가입니다. "
        f"사용자의 일기를 보고, **{emotion_label}** 감정을 기반으로 공감과 위로를 담아 "
        "50자 이내의 짧고 격려가 되는 코멘트를 한국어로 작성하세요."
    )
    
# Llama 모델에 맞는 프롬프트 형식
    prompt = f"""아래는 작업을 설명하는 지시사항입니다. 입력된 내용을 바탕으로 적절한 응답을 작성하세요.
### 지시사항:
{system_instruction}
### 입력:
{safe_text}
### 응답:
"""
    try:
        inputs = tokenizer(prompt, return_tensor="pt").to(DEVICE)
        
        ## 모델 추론
        with torch.no_grad():
            outputs = model.generate(
            **inputs,
            max_length=inputs['input_ids'].shape[1] + MAX_OUTPUT_TOKENS, # 출력 길이를 50자 토큰으로 제한 (입력 길이 + 50)
            temperature=TEMPERATURE,
            top_p=0.9,
            do_sample=True,
            pad_token_id=tokenizer.pad_token_id,
            num_return_sequences=1
        )
        generated_text = tokenizer.decode(outputs[0], skip_special_tokens=True)
        response = generated_text.split("### 응답:\n")[-1].strip()
        
        if len(response) > 50:
            return response[:50].strip() + "..."
        
        return response
    
    except Exception as e:
        print(f"ERROR during comment generation: {e}")
        return f"AI 코멘트 생성 실패: {emotion_label}에 대한 응답을 생성하지 못했습니다."
