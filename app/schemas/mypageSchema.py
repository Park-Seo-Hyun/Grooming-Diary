# backend/schemas/mypageSchema.py
from pydantic import BaseModel, Field
from datetime import date, datetime

class mypageResponse(BaseModel):
    user_name: str = Field(..., description="사용자 이름")
    user_id: str = Field(..., description="사용자 아이디")
    start_date: int = Field(..., description="가입한지")
    created_at: date = Field(..., description="가입 날짜")
    user_emotion_score: float = Field(..., description="총합 감정 점수")