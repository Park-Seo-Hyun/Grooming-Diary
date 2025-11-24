# backend/schemas/graphSchema.py

from pydantic import BaseModel, Field
from typing import List

## 월별 그래프 데이터 가져오기 (월별 감정, 감정 개수, 감정 모지 + 백분율)
class EmotionStateItem(BaseModel):
    emotion_label: str = Field(..., description="감정 이름")
    emotion_emoji: str = Field(..., description="감정 이모지")
    emotion_cnt: int = Field(..., description="감정 발생 개수")
    emotion_percent: float = Field(..., description="감정 백분율")
    
## 일별 감정 점수 담기 -> 추이 그래프에 사용
class DailyEmotionScore(BaseModel):
    date: str = Field(..., description="날짜 (YYYY-MM-DD)")
    Angry: float = Field(..., description="분노 점수 (0.0~1.0)")
    Fear: float = Field(..., description="공포 점수 (0.0~1.0)")
    Happy: float = Field(..., description="행복 점수 (0.0~1.0)")
    Tender: float = Field(..., description="부드러움 점수 (0.0~1.0)")
    Sad: float = Field(..., description="슬픔 점수 (0.0~1.0)")

## 월별 데이터 통계
class MonthlyStateResponse(BaseModel):
    monthly_year: str = Field(..., description="조회 날짜(YYYY-MM)", examples=["2025-11"])
    diary_cnt: int = Field(..., description="일기 작성 횟수")
    emotion_state: List[EmotionStateItem] = Field(..., description="월별 감정 정보")
    daily_emotion_scores: List[DailyEmotionScore] = Field(..., description="월별 일일 감정 점수")
