# backend/router/main_diary.py
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import date, datetime, timedelta
from typing import List, Dict, Any

from ..models.user import User 
from ..models.diary import Diary 
from .. import auth
from ..schemas import diarySchema, userSchema
from ..database import get_db
from ..service import nlp_service, chatbot_service

router = APIRouter(
    prefix="/api/diaries", 
    tags=["Diaries"],
    responses={404:{"description": "Not found"}}
)

## JWT 토큰 검증 후 DB에서 User 객체 가져옴
def get_current_active_user(user_id: str = Depends(auth.get_current_user), db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="사용자를 찾을 수 없습니다.")
    return user

## 감정 중요도 가중치 (임시)
EMOTION_WEIGHTS = {
    "Happy": 3,
    "Tender": 1,
    "Fear": -2,
    "Angry": -3,
    "Sad": -4,
}

## helper function
def create_diary_response(diary: Diary) -> dict:
    
    if diary.image_url: ## 사용자가 이미지를 첨부했을 경우
        primary_url = diary.image_url
    else: ## 이미지를 첨부하지 않았을 경우
        primary_url = f"/static/emoji/{diary.emotion_emoji}"
    
    ## 감정 점수 (0~100) 변환
    emotion_score_100 = round(diary.emotion_score * 100, 1)
    
    return {
        "id": diary.id,
        "user_id": diary.user_id,
        "diary_date": diary.diary_date,
        "content": diary.content,
        "image_url": diary.image_url,
        
        "primary_image_url": primary_url, ## 최종 이미지
        "emotion_score": emotion_score_100, ## 최대 100점으로 변환한 감정 점수
        "emotion_emoji": diary.emotion_emoji,
        "emotion_label": diary.emotion_label,
        "ai_comment": diary.ai_comment,
        
        "created_at": diary.created_at,
    }
    
# 일기 Create
@router.post("/new", response_model=diarySchema.DiaryResponse, status_code=status.HTTP_201_CREATED)
def create_diary(
    diary_data: diarySchema.DiaryCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user) ## JWT 인증 적용
):
    analysis_result = nlp_service.get_emotion_analysis(diary_data.content) ## 일기 감정 분석(NLP)
    
    ai_comment_text = chatbot_service.generate_comment(diary_data.content, analysis_result['emotion_label'])
    
    ## DB 객체 생성 및 저장
    new_diary = Diary(
        user_id=current_user.id,
        
        diary_date=diary_data.diary_date,
        content=diary_data.content,
        image_url=diary_data.image_url,
        
        ## 감정분석결과 저장
        emotion_score=analysis_result['emotion_score'],
        emotion_emoji=analysis_result['emotion_emoji'],
        emotion_label=analysis_result['emotion_label'],
        
        ## AI봇 코멘트 결과
        ai_comment=ai_comment_text
    )
    
    db.add(new_diary)
    db.commit()
    db.refresh(new_diary)
    
    full_data = create_diary_response(new_diary) 
    return diarySchema.DiaryResponse(**full_data)

# # 전체 일기 조회
# @router.get("/main", response_model=diarySchema.MainPageResponse)
# def get_all_diaries(
#     db: Session = Depends(get_db),
#     current_user: User = Depends(get_current_active_user)
# ):
#     ## 모든 일기 데이터 조회
#     diaries = db.query(Diary).filter(Diary.user_id == current_user.id).order_by(Diary.diary_date.desc()).all()
    
#     ## 감정 점수 종합 계산
#     emotion_counts = {label: 0 for label in EMOTION_WEIGHTS.keys()}
#     total_weighted_score = 0
#     max_possible_weight = max(EMOTION_WEIGHTS.values())
#     min_possible_weight = min(EMOTION_WEIGHTS.values())
    
#     calendar_items = []
    
    

## 특정 일기 상세 조회 
@router.get("/date/{id}", response_model=diarySchema.DiaryDetailResponse)
def get_diary_detail(
    id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    ## user_id와 id를 통해 일기 조회
    diary = db.query(Diary).filter(
        Diary.user_id == current_user.id,
        Diary.id == id
    ).first()
    
    if not diary:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"ID {id}에 해당하는 일기를 찾을 수 없습니다.")

    full_data = create_diary_response(diary)
    return diarySchema.DiaryDetailResponse(**full_data)