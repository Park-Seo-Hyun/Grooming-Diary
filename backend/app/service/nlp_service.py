#backend/app/service/nlp_service.py

from transformers import AutoTokenizer, BertForSequenceClassification
import torch
import torch.nn.functional as F
import os
from typing import Dict, Any

MODEL_NAME = "jeonghyeon97/koBERT-Senti5"

## 감정 레이블 정의
EMOTION_LABELS = {
    0: ("Angry", "angry.png"),
    1: ("Fear", "fear.png"),
    2: ("Happy", "happy.png"),
    3: ("Tender", "tender.png"),
    4: ("Sad", "sad.png") 
}

# 토크나이저 및 모델 로드
try:
    # KoBERT의 원래 토크나이저 사용
    tokenizer = AutoTokenizer.from_pretrained('monologg/kobert', trust_remote_code=True)
    
    # 모델 로드 (GPU가 있다면 GPU, 없다면 CPU)
    DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    model = BertForSequenceClassification.from_pretrained(MODEL_NAME).to(DEVICE)
    
    print(f"INFO: NLP model {MODEL_NAME} loaded successfully on {DEVICE}.")
except Exception as e:
    print(f"ERROR: Failed to load NLP model: {e}")
    # 모델 로딩 실패 시 더미 함수로 대체하여 서버는 계속 작동하도록 함
    def tokenizer(*args, **kwargs): return {}
    def model(*args, **kwargs): pass
    DEVICE = "cpu"


def get_emotion_analysis(text: str) -> dict:
    """
    사용자의 일기 텍스트를 분석하여 감정 레이블, 점수, 이모지 파일명을 반환합니다.
    """
    
    # 텍스트 토큰화
    inputs = tokenizer(text, return_tensors='pt', padding=True, truncation=True).to(DEVICE)
    
    # 모델 추론
    with torch.no_grad():
        outputs = model(**inputs)
        
    ## 확률 계산 (Softmax 적용)
    # # probabilities: 모든 감정 레이블의 확률 리스트 (e.g., [0.05, 0.10, 0.70, 0.05, 0.10])
    probabilities = F.softmax(outputs.logits, dim=1).squeeze().tolist()
    
    # 가장 높은 확률을 가진 감정의 인덱스 추출
    predicted_label_index = torch.argmax(outputs.logits, dim=1).item()
    
    # 결과 매핑
    emotion_score = probabilities[predicted_label_index]
    emotion_label = EMOTION_LABELS[predicted_label_index][0]
    emotion_emoji = EMOTION_LABELS[predicted_label_index][1]
    
    overall_emotion_score: Dict[str, float] = {}
    for i, (label, _) in EMOTION_LABELS.items():
        overall_emotion_score[label] = probabilities[i]
    
    return {
        "emotion_label": emotion_label,
        "emotion_emoji": emotion_emoji,
        "emotion_score": emotion_score,
        "overall_emotion_score": overall_emotion_score
    }
