#backend/app/service/nlp_service.py

# 토크나이저 및 모델 로드
from transformers import AutoTokenizer, AutoModelForSequenceClassification
import torch
import torch.nn.functional as F

# KoBERT 토크나이저와 모델 로드
tokenizer = AutoTokenizer.from_pretrained("monologg/kobert", trust_remote_code=True)
model = AutoModelForSequenceClassification.from_pretrained("rkdaldus/ko-sent5-classification")

# 감정 레이블 정의

EMOTION_LABELS = {
    0: ("Angry", "angry.png"),
    1: ("Fear", "fear.png"),
    2: ("Happy", "happy.png"),
    3: ("Tender", "tender.png"),
    4: ("Sad", "sad.png")
}

def get_emotion_analysis(text: str) -> dict:
    ## 텍스트 토큰화
    inputs = tokenizer(text, return_tensors="pt", padding=True, truncation=True)
    
    ## 모델 추론
    with torch.no_grad():
        outputs = model(**inputs)
        
    ## 확률 계산
    probabilities = F.softmax(outputs.logits, dim=1).squeeze().tolist()
    
    predicted_label = torch.argmax(outputs.logits, dim=1).item()
    
    emotion_score = probabilities[predicted_label]
    emotion_label = EMOTION_LABELS[predicted_label][0]
    emotion_emoji = EMOTION_LABELS[predicted_label][1]
    
    return {
        "emotion_label": emotion_label,
        "emotion_emoji": emotion_emoji,
        "emotion_score": emotion_score
    }