# backend/schemas/graphSchema.py

from pydantic import BaseModel, Field
from typing import List

## 월별 그래프 데이터 가져오기 (월별 감정, 감정 개수, 감정 모지 + 백분율)
class EmotionStateItem(BaseModel):
    emotion_label: str = Field(..., description="감정 이름")
    emotion_emoji: str = Field(..., description="감정 이모지")
    emotion_cnt: int = Field(..., description="감정 발생 개수")
    emotion_percent: float = Field(..., description="감정 백분율")

## 월별 데이터 통계
class MonthlyStateResponse(BaseModel):
    month_year: str = Field(..., description="조회 날짜(YYYY-MM)", examples=["2025-11"])
    diary_cnt: int = Field(..., description="일기 작성 횟수")
    emotion_state: List[EmotionStateItem] = Field(..., description="월별 감정 정보")
