# backend/app/ai_model/nlp_service.py
import torch
import torch.nn.functional as F
import os
from typing import Dict, Any

FINE_TUNED_MODEL_PATH = r"D:/Grooming/backend/app/ai_model/fintunning_nlp" 

EMOTION_LABELS = {
    0: ("Angry", "angry.png"),
    1: ("Fear", "fear.png"), 
    2: ("Happy", "happy.png"), 
    3: ("Tender", "tender.png"), 
    4: ("Sad", "sad.png") 
}

## 임계값 (임시)
CONFIDENCE_THRESHOLD = 0.65

# '중립' 감정 레이블 정보 (모델이 확신하지 못할 때 사용)
NEUTRAL_EMOTION = {
    "emotion_label": "Neutral",
    "emotion_emoji": "default.png" 
}

try:
    from transformers import AutoTokenizer, AutoModelForSequenceClassification 
    
    tokenizer = AutoTokenizer.from_pretrained('monologg/kobert', trust_remote_code=True)
    
    DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    
    model = AutoModelForSequenceClassification.from_pretrained(FINE_TUNED_MODEL_PATH, trust_remote_code=True).to(DEVICE)
    model.eval() # 추론 모드로 설정
    
    print(f"INFO: Fine-tuned NLP model loaded successfully from {FINE_TUNED_MODEL_PATH} on {DEVICE}.")
    LOAD_SUCCESS = True
except ImportError:
    print(f"ERROR: 'transformers' 라이브러리가 설치되지 않았습니다.")
    LOAD_SUCCESS = False
except OSError as e:
    print(f"ERROR: Failed to load NLP model from {FINE_TUNED_MODEL_PATH}. 경로 및 파일 존재 여부 확인 필요. 상세 오류: {e}")
    LOAD_SUCCESS = False
except Exception as e:
    print(f"ERROR: Failed to load NLP model: {e}")
    LOAD_SUCCESS = False

# 모델 로딩 실패 시 더미 함수로 대체 (기존 로직 유지)
if not LOAD_SUCCESS:
    def tokenizer(text, **kwargs): return {'input_ids': torch.tensor([[101, 102]]), 'attention_mask': torch.tensor([[1, 1]])}
    
    class DummyModel:
        def __call__(self, **kwargs):
            return type('Outputs', (object,), {'logits': torch.tensor([[0.1, 0.1, 10.0, 0.1, 0.1]])})
        def to(self, device): return self
        def eval(self): pass
        
    model = DummyModel()
    DEVICE = "cpu"

def get_emotion_analysis(text: str) -> dict:
    if not text or not LOAD_SUCCESS:
        # 모델 로딩 실패 또는 텍스트가 비어 있을 경우 기본값 반환
        return {
            "emotion_label": NEUTRAL_EMOTION["emotion_label"],
            "emotion_emoji": NEUTRAL_EMOTION["emotion_emoji"],
            "emotion_score": 0.0,
            "overall_emotion_score": {label[0]: 0.0 for label in EMOTION_LABELS.values()}
        }
        
    # 텍스트 토큰화
    inputs = tokenizer(
        text, 
        return_tensors='pt', 
        padding=True, 
        truncation=True,
        max_length=128 
    ).to(DEVICE)
    
    # 모델 추론
    with torch.no_grad():
        outputs = model(**inputs)
        
    ## 확률 계산 (Softmax 적용)
    # probabilities: 모든 감정 레이블의 확률 리스트 
    probabilities = F.softmax(outputs.logits, dim=1).squeeze().tolist()
    
    # 가장 높은 확률을 가진 감정의 인덱스 추출
    predicted_label_index = torch.argmax(outputs.logits, dim=1).item()
    
    # 가장 높은 확률값
    emotion_score = probabilities[predicted_label_index]
    
    if emotion_score < CONFIDENCE_THRESHOLD:
        # 확률이 임계값 미만일 경우 '중립'으로 강제 전환
        emotion_label = NEUTRAL_EMOTION["emotion_label"]
        emotion_emoji = NEUTRAL_EMOTION["emotion_emoji"]
    else:
        # 임계값 이상일 경우 원래 예측 결과 사용
        emotion_label = EMOTION_LABELS[predicted_label_index][0]
        emotion_emoji = EMOTION_LABELS[predicted_label_index][1]
    
    overall_emotion_score: Dict[str, float] = {}
    
    # 전체 감정 점수 매핑 
    for i, (label, _) in EMOTION_LABELS.items():
        if i < len(probabilities):
            overall_emotion_score[label] = probabilities[i]
    
    return {
        "emotion_label": emotion_label,
        "emotion_emoji": emotion_emoji,
        "emotion_score": emotion_score,
        "overall_emotion_score": overall_emotion_score
    }