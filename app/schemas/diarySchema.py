#backend/app/diarySchema.py

from pydantic import BaseModel, Field
from datetime import date, datetime
from typing import Dict, Optional, List

## 일기 Create
class DiaryCreate(BaseModel):
    diary_date: date = Field(..., description="일기 작성 날짜(YYYY-MM-DD)", example="2025-11-13")
    content: str = Field(..., max_length=100, description="일기 내용(최대 100자)")
    image_url: Optional[str] = Field(None, description="첨부 이미지 url")
    
## 일기 Update
class DiaryUpdate(BaseModel):
    content: Optional[str] = Field(None, max_length=100, description="일기 수정")
    image_url: Optional[str] = Field(None, description="첨부 이미지 수정")
    
## 생성된 다이어리 데이터 RESPONSE
class DiaryResponse(BaseModel):
    id: str = Field(..., description="일기 UUID")
    user_id: str = Field(..., description="사용자 UUID")
    
    diary_date: date = Field(..., description="일기 작성 날짜")
    content: str = Field(..., description="일기 내용")
    
    image_url: Optional[str] = Field(None, description="첨부 이미지")
    primary_image_url: str = Field(..., description="달력에 표시할 최종 이미지 URL")
    
    emotion_score: float = Field(..., description="감정 점수")
    emotion_emoji: str = Field(..., max_length=255, description="감정 이모지")
    emotion_label: str = Field(..., description="감정 레이블")
    overall_emotion_score: Dict[str, float] = Field(..., description="전체 감정 분포")
    
    ai_comment: str = Field(..., max_length=200, description="AI 쳇봇 코멘트")
    
    created_at: datetime = Field(..., description="생성 시각")
    
    class Config:
        from_attributes = True

    
## 특정 다이어리 데이터 RESPONSE
class DiaryDetailResponse(BaseModel):
    id: str = Field(..., description="일기 UUID")
    user_name: str = Field(..., description="사용자 이름")
    diary_date: date = Field(..., description="일기 작성 날짜")
    primary_image_url: str = Field(..., description="달력에 표시할 최종 이미지 URL")
    content: str = Field(..., description="일기 내용")
    ai_comment: str = Field(..., max_length=200, description="AI 쳇봇 코멘트")
    
    class Config:
        from_attributes = True
        
## 달력 main 데이터 RESPONSE
class CalendarResponse(BaseModel):
    id: str = Field(..., description="일기 UUID")
    diary_date: date = Field(..., description="일기 작성 날짜")
    emotion_emoji: str = Field(..., max_length=255, description="감정 이모지")
    
    class Config:
        from_attributes = True
        
## 달력 main 통합 RESPONSE
class MainPageResponse(BaseModel):
    monthly_year: str = Field(..., description="달력 날짜", examples=["2025-11"])
    monthly_name_en: str = Field(..., description="월 영어")
    user_emotion_score: float = Field(..., description="총합 감정 점수")
    diaries: List[CalendarResponse] = Field(..., description="달력 표시용")
        
    
    
    