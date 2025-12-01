import torch
import torch.nn.functional as F
import os
from typing import Dict, Any

# ⚠️ 수정: 파인튜닝된 모델의 weights가 저장된 로컬 경로
FINE_TUNED_MODEL_PATH = r"D:/Grooming/backend/app/ai_model/fine_tuned_kobert_nlp" 
# NOTE: 실제 사용자 환경에 맞게 위의 경로를 'FINE_TUNED_MODEL_PATH' 변수에 정확히 설정해야 합니다.

# 🌟 파인튜닝 시 사용한 레이블 순서와 동일하게 매핑 (매우 중요)
# finetune_kobert.py: EMOTION_LABELS_MAP = {"Angry": 0, "Fear": 1, "Happy": 2, "Tender": 3, "Sad": 4}
EMOTION_LABELS = {
    0: ("Angry", "angry.png"),   # ID 0
    1: ("Fear", "fear.png"),     # ID 1
    2: ("Happy", "happy.png"),   # ID 2
    3: ("Tender", "tender.png"), # ID 3
    4: ("Sad", "sad.png")        # ID 4
}

# -------------------------- 모델 및 토크나이저 로드 --------------------------
# 모델 로딩을 위한 Dynamic Import (transformers는 모델 타입을 자동으로 추론)
try:
    from transformers import AutoTokenizer, AutoModelForSequenceClassification 
    
    # 🌟 FIX 1: 토크나이저는 오류 방지를 위해 KoBERT의 오리지널 소스 ('monologg/kobert')에서 로드합니다.
    # 토크나이저의 설정 파일 누락 문제를 해결합니다.
    tokenizer = AutoTokenizer.from_pretrained('monologg/kobert', trust_remote_code=True)
    
    # 모델 로드 (GPU가 있다면 GPU, 없다면 CPU)
    DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    
    # 🌟 FIX 2: 모델 weights는 로컬 경로에서 파인튜닝된 버전을 로드합니다.
    model = AutoModelForSequenceClassification.from_pretrained(FINE_TUNED_MODEL_PATH, trust_remote_code=True).to(DEVICE)
    model.eval() # 추론 모드로 설정
    
    print(f"INFO: Fine-tuned NLP model loaded successfully from {FINE_TUNED_MODEL_PATH} on {DEVICE}.")
    LOAD_SUCCESS = True
except ImportError:
    print(f"ERROR: 'transformers' 라이브러리가 설치되지 않았습니다.")
    LOAD_SUCCESS = False
except OSError as e:
    # ⚠️ 이제 OSError는 경로 문제 또는 파일 누락 문제일 가능성이 높습니다.
    print(f"ERROR: Failed to load NLP model from {FINE_TUNED_MODEL_PATH}. 경로 및 파일 존재 여부 확인 필요. 상세 오류: {e}")
    LOAD_SUCCESS = False
except Exception as e:
    print(f"ERROR: Failed to load NLP model: {e}")
    LOAD_SUCCESS = False

# 모델 로딩 실패 시 더미 함수로 대체
if not LOAD_SUCCESS:
    def tokenizer(text, **kwargs): return {'input_ids': torch.tensor([[101, 102]]), 'attention_mask': torch.tensor([[1, 1]])}
    
    class DummyModel:
        def __call__(self, **kwargs):
            # 5개 레이블에 대한 더미 로짓 반환 (Happy로 가정)
            return type('Outputs', (object,), {'logits': torch.tensor([[0.1, 0.1, 10.0, 0.1, 0.1]])})
        def to(self, device): return self
        def eval(self): pass
        
    model = DummyModel()
    DEVICE = "cpu"
# ---------------------------------------------------------------------


def get_emotion_analysis(text: str) -> dict:
    """
    사용자의 일기 텍스트를 분석하여 감정 레이블, 점수, 이모지 파일명을 반환합니다.
    """
    if not text or not LOAD_SUCCESS:
        # 모델 로딩 실패 또는 텍스트가 비어 있을 경우 기본값 반환
        return {
            "emotion_label": "Neutral",
            "emotion_emoji": "default.png",
            "emotion_score": 0.0,
            "overall_emotion_score": {label[0]: 0.0 for label in EMOTION_LABELS.values()}
        }
        
    # 텍스트 토큰화
    inputs = tokenizer(
        text, 
        return_tensors='pt', 
        padding=True, 
        truncation=True,
        max_length=128 # 학습 시 사용한 MAX_LENGTH와 동일하게 설정
    ).to(DEVICE)
    
    # 모델 추론
    with torch.no_grad():
        outputs = model(**inputs)
        
    ## 확률 계산 (Softmax 적용)
    # probabilities: 모든 감정 레이블의 확률 리스트 
    probabilities = F.softmax(outputs.logits, dim=1).squeeze().tolist()
    
    # 가장 높은 확률을 가진 감정의 인덱스 추출
    predicted_label_index = torch.argmax(outputs.logits, dim=1).item()
    
    # 결과 매핑
    emotion_score = probabilities[predicted_label_index]
    emotion_label = EMOTION_LABELS[predicted_label_index][0]
    emotion_emoji = EMOTION_LABELS[predicted_label_index][1]
    
    overall_emotion_score: Dict[str, float] = {}
    
    # 전체 감정 점수 매핑 (파인튜닝된 모델의 출력 순서에 따라)
    for i, (label, _) in EMOTION_LABELS.items():
        # probabilities 리스트가 EMOTION_LABELS의 인덱스 순서(0, 1, 2, 3, 4)와 일치해야 합니다.
        if i < len(probabilities):
            overall_emotion_score[label] = probabilities[i]
    
    return {
        "emotion_label": emotion_label,
        "emotion_emoji": emotion_emoji,
        "emotion_score": emotion_score,
        "overall_emotion_score": overall_emotion_score
    }