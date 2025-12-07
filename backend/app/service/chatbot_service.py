# backend/app/ai_model/chatbot_service.py
from transformers import AutoTokenizer, AutoModelForSeq2SeqLM
import torch
import torch.nn.functional as F
import os
from typing import Dict, Any


LOCAL_MODEL_PATH = os.getenv(
    "LOCAL_MODEL_PATH", 
    "D:/Grooming/backend/app/ai_model/chatbot_model"
)


LOAD_SUCCESS = False
try:
    # 1. KoBART 토크나이저 로드 (학습된 모델 경로에서 로드)
    tokenizer = AutoTokenizer.from_pretrained(LOCAL_MODEL_PATH)

    DEVICE = torch.device("cpu") # 배포 환경에 따라 "cuda" 또는 "cpu" 선택
    
    model = AutoModelForSeq2SeqLM.from_pretrained(LOCAL_MODEL_PATH).to(DEVICE)
    model.eval()
    
    print(f"INFO: KoBART Diary Comment model loaded successfully from local path on {DEVICE}.")
    LOAD_SUCCESS = True

except Exception as e:
    print(f"ERROR: Failed to load KoBART model from {LOCAL_MODEL_PATH}. Error: {e}")

    def tokenizer(*args, **kwargs):
        # 최소한의 더미 출력을 반환
        return {'input_ids': torch.tensor([[1]]), 'attention_mask': torch.tensor([[1]])}
    
    class DummyModel:
        def generate(self, input_ids, **kwargs):
            # 더미 출력 
            return torch.tensor([[1, 512, 512]])

        def to(self, device): return self
        def eval(self): pass

    model = DummyModel()
    DEVICE = "cpu"
    LOAD_SUCCESS = False


def generate_comment(content: str) -> str:
    if not LOAD_SUCCESS:
        return "현재 AI 챗봇 모델 로딩에 실패했습니다. 관리자에게 문의하세요."
        
    prompt = content.strip() 
    
    try:
        inputs = tokenizer(prompt, return_tensors="pt").to(DEVICE)
        
        # KoBART 생성 파라미터 최적화
        MAX_NEW_TOKENS = 40
        # TEMPERATURE = 0.7  <-- 제거됨
        # TOP_P = 0.9        <-- 제거됨
        REPETITION_PENALTY = 1.8
        NO_REPEAT_NGRAM_SIZE = 2
        

        NUM_BEAMS = 7
        NUM_RETURN_SEQUENCES = 3
        
        LENGTH_PENALTY = 2.0       # 답변 길이 유도
        DIVERSITY_PENALTY = 0.5       # 후보군 간 다양성 확보
        
        with torch.no_grad():
            outputs = model.generate(
                inputs.input_ids,
                attention_mask=inputs.attention_mask,
                max_new_tokens=MAX_NEW_TOKENS,
                do_sample=False,          
                num_beams=NUM_BEAMS,     
                num_return_sequences=NUM_RETURN_SEQUENCES,
                length_penalty=LENGTH_PENALTY,            # 길이 보상
                diversity_penalty=DIVERSITY_PENALTY,
                repetition_penalty=REPETITION_PENALTY,
                no_repeat_ngram_size=NO_REPEAT_NGRAM_SIZE,
                pad_token_id=tokenizer.pad_token_id,
                eos_token_id=tokenizer.eos_token_id,
            )
        
        candidates = [tokenizer.decode(output, skip_special_tokens=True).strip() for output in outputs]
        generated_text = max(candidates, key=len)
        
        response = generated_text.strip()
        
        # 2. 불필요한 공백 및 문장 잔여물 제거
        if "\n" in response:
            response = response.split("\n")[0].strip()
        
        # 3. 마침표 추가 (깔끔한 코멘트를 위해)
        if response and not response.endswith(('.', '!', '?')):
            response += '.'
            
        # 4. 길이 제한
        if len(response) > 197:
            response = response[:197].strip() + "..."
            
        return response

    except Exception as e:
        print(f"ERROR during comment generation: {e}")
        return "야, 미안! 지금 AI 친구가 잠깐 정신을 놨어. 다시 한번 시도해볼게."