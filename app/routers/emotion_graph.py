# backend/router/emotion_graph.py

from fastapi import APIRouter, Depends, HTTPException, status, Query, Path
from sqlalchemy.orm import Session
from datetime import date, datetime, timedelta
from typing import List, Dict, Any
import calendar

from ..models.user import User 
from ..models.diary import Diary 
from .. import auth
from ..schemas import graphSchema
from ..database import get_db
from ..routers.main_diary import get_current_active_user

router = APIRouter(
    prefix="/api/graphs", 
    tags=["Graph"],
    responses={404:{"description": "Not found"}}
)

EMOTION_LABEL = ["Angry", "Fear", "Happy", "Tender", "Sad", "Neutral"]

@router.get("/monthly/{monthly_year}", response_model=graphSchema.MonthlyStateResponse)
def get_monthly_emotion(
    monthly_year: str = Path(..., description="조회 날짜(YYYY-MM)", examples=["2025-11"]),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    user_id = current_user.id
    
    try:
        start_date = datetime.strptime(monthly_year, "%Y-%m").date()
        _, days_in_month = calendar.monthrange(start_date.year, start_date.month)
        end_date = date(start_date.year, start_date.month, days_in_month)
        
    except ValueError:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="날짜 형식이 유효하지 않습니다.(YYYY-MM)")

    diaries_in_month = db.query(Diary)\
        .filter(
            Diary.user_id == user_id,
            Diary.diary_date >= start_date,
            Diary.diary_date <= end_date
        ).all()
    total_diary_cnt = len(diaries_in_month)
    
    emotion_cnt = {label: 0 for label in EMOTION_LABEL}
    
    for diary in diaries_in_month:
        label = diary.emotion_label
        emotion_cnt[label] += 1
        
    emotion_state = []
    if total_diary_cnt > 0:
        for label in EMOTION_LABEL:
            cnt = emotion_cnt[label]
            if cnt == 0:
                continue
            percent = round((cnt / total_diary_cnt) * 100, 1)

            emotion_state.append(graphSchema.EmotionStateItem(
                emotion_label=label,
                emotion_emoji=f"/static/emoji/{label.lower()}.png",
                emotion_cnt=cnt,
                emotion_percent=percent
            ))
    
    return {
        "month_year": monthly_year,
        "diary_cnt": total_diary_cnt,
        "emotion_state": emotion_state
    }
    