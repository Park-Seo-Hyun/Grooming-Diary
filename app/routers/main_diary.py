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

## 감정 점수 임계값 설정 (이 값 미만이면 'Neutral'로 처리)
EMOTION_SCORE_THRESHOLD = 0.60

## 감정 중요도 가중치 (임시)
EMOTION_WEIGHTS = {
    "Angry": 4,
    "Fear": 3,
    "Happy": 2,
    "Tender": 2,
    "Sad": 5,
    "Neutral": 1,
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
    
# 전체 일기 조회
@router.get("/main", response_model=diarySchema.MainPageResponse)
def get_all_diaries(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    user_id = current_user.id
    today = date.today()
    thirty_days = today - timedelta(days=30)
   
    ## 감정 점수 계산 용 일기 데이터 조회 (최근 30일 이내 데이터)
    recent_diaries = db.query(Diary).filter(Diary.user_id == user_id, Diary.diary_date >= thirty_days)\
        .order_by(Diary.diary_date.desc()).all()
       
    total_score = 0
    total_cnt = len(recent_diaries)

    for diary in recent_diaries:
        label = diary.emotion_label
        weight = EMOTION_WEIGHTS.get(label)
        total_score += weight * diary.emotion_score
        
    max_weight = max(EMOTION_WEIGHTS.values())
    min_weight = min(EMOTION_WEIGHTS.values())
    
    ## total 감정 점수
    if total_cnt > 0:
        min_possible_score = total_cnt * min_weight
        max_possible_score = total_cnt * max_weight
        
        score_range = max_possible_score - min_possible_score
        ## 분모 0 방지
        if score_range == 0:
            overall_emotion_score = 50.0
        else:
            normalized_score = (total_score - min_possible_score) / score_range
            overall_emotion_score = round(max(0.0, min(1.0, normalized_score)) * 100, 1)
    else:
        overall_emotion_score = 0.0
    
    ## 달력 표시용 데이터
    all_diaries = db.query(Diary).filter(Diary.user_id == user_id).order_by(Diary.diary_date.desc()).all()

    calendar_diaries = []

    for entry in all_diaries:
        calendar_diaries.append(diarySchema.CalendarResponse(
            id=entry.id,
            diary_date=entry.diary_date,
            emotion_emoji=entry.emotion_emoji
        ))
        
    return {
        "overall_emotion_score": overall_emotion_score,
        "diaries": calendar_diaries
    }
    
# 일기 Create
@router.post("/new", response_model=diarySchema.DiaryResponse, status_code=status.HTTP_201_CREATED)
def create_diary(
    diary_data: diarySchema.DiaryCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user) ## JWT 인증 적용
):
    
    ## NLP/AI봇 실패 시 사용할 기본값 정의
    analysis_result = {
        'emotion_score': 0.0,
        'emotion_emoji': None,
        'emotion_label': "Neutral"
    }
    ai_comment_text = "오늘 너는 여러가지 감정이 섞인 하루를 보냈구나"
    
    # FIX: NLP 서비스 예외 처리 및 감정 점수 임계값 적용
    try:
        raw_analysis = nlp_service.get_emotion_analysis(diary_data.content)
        
        ## 감정 점수가 임계값 미만일 경우, Neutral로 강제 처리 
        if raw_analysis['emotion_score'] < EMOTION_SCORE_THRESHOLD:
            analysis_result['emotion_label'] = "Neutral"
            analysis_result['emotion_emoji'] = "default.png" 
            analysis_result['emotion_score'] = raw_analysis['emotion_score'] ## 점수는 유지
        else:
            analysis_result = raw_analysis
            
        ## AI 코멘트 재생성
        ai_comment_text = chatbot_service.generate_comment(diary_data.content, analysis_result['emotion_label'])
        
    except Exception as e:
        print(f"NLP/Chatbot Service Failed: {e}")
        ## 실패 시 ai_comment_text와 analysis_result는 기본값 유지
    
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

## 특정 일기 수정
@router.put("/modify/{id}", response_model=diarySchema.DiaryDetailResponse)
def update_diary(
    id: str,
    update_data: diarySchema.DiaryUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    diary_query = db.query(Diary).filter(
        Diary.user_id == current_user.id,
        Diary.id == id
    )
    diary = diary_query.first()
    
    if not diary:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"ID {id}에 해당하는 일기를 찾을 수 없습니다.")
    
    
    ## NLP/AI봇 실패 시 사용할 기본값 정의
    analysis_result = {
        'emotion_score': diary.emotion_score or 0.0,
        'emotion_emoji': diary.emotion_emoji or None,
        'emotion_label': diary.emotion_label or "Neutral"
    }
    ai_comment_text = diary.ai_comment or "오늘 너는 여러가지 감정이 섞인 하루를 보냈구나"
    
    if update_data.content and update_data.content != diary.content:
        try:
            raw_analysis = nlp_service.get_emotion_analysis(update_data.content)

            if raw_analysis['emotion_score'] >= EMOTION_SCORE_THRESHOLD:
                analysis_result = raw_analysis
            else:
                analysis_result['emotion_score'] = raw_analysis['emotion_score']
                analysis_result['emotion_label'] = "Neutral"
                analysis_result['emotion_emoji'] = "default.png" 

            ## AI 코멘트 재생성
            ai_comment_text = chatbot_service.generate_comment(update_data.content, analysis_result['emotion_label'])

        except Exception as e:
            print(f"NLP/Chatbot Service Failed: {e}")
            ## 실패 시 ai_comment_text와 analysis_result는 기본값 유지
            
    update_data_dict = update_data.model_dump(exclude_unset=True)
    
    update_payload = {
        **update_data_dict,
        "emotion_score": analysis_result['emotion_score'],
        "emotion_emoji": analysis_result['emotion_emoji'],
        "emotion_label": analysis_result['emotion_label'],
        "ai_comment": ai_comment_text,
    }
    diary_query.update(update_payload, synchronize_session=False)
    db.commit()
    db.refresh(diary)
    
    full_data = create_diary_response(diary)
    return diarySchema.DiaryDetailResponse(**full_data)

## 일기 삭제
@router.delete("/{id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_diary(
    id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    diary = db.query(Diary).filter(
        Diary.user_id == current_user.id,
        Diary.id == id
    )
    
    if not diary.first():
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"ID {id}에 해당하는 일기를 찾을 수 없거나 삭제 권한이 없습니다.")

    diary.delete(synchronize_session=False)
    db.commit()
    
    return