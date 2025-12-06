# backend/router/mypage.py
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import date, datetime, timedelta
from ..models.user import User
from ..models.diary import Diary
from ..schemas import mypageSchema
from ..database import get_db
from ..routers.main_diary import get_current_active_user, calculate_emotion_score
import calendar

router = APIRouter(
    prefix="/api/mypage",
    tags=["My Page"]
)

## 감정 중요도 가중치 (임시)
EMOTION_WEIGHTS = {
    "Angry": -4, # 가장 부정
    "Fear": -2,
    "Sad": -3,
    "Happy": 4,  # 가장 긍정
    "Tender": 2,
    "Neutral": 1, # 중립
}

@router.get("", response_model=mypageSchema.mypageResponse)
def my_page(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    user_pk = current_user.id
    user_id = current_user.user_id
    user_name = current_user.user_name
    created_at = current_user.created_at.date()
    
    today = date.today()
    start_date = (today - created_at).days
    thirty_days = today - timedelta(days=30)
    
    ## 감정 점수 계산 용 일기 데이터 조회 (최근 30일 이내 데이터)
    recent_diaries = db.query(Diary).filter(Diary.user_id == user_pk, Diary.diary_date >= thirty_days)\
        .order_by(Diary.diary_date.desc()).all()
       
    user_emotion_score = calculate_emotion_score(diaries=recent_diaries, weights=EMOTION_WEIGHTS)
    
    return {
        "user_name": user_name,
        "user_id": user_id,
        "start_date": start_date,
        "created_at": created_at,
        "user_emotion_score": user_emotion_score
    }

    
    
    
    