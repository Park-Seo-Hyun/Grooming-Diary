# backend/app/router/main_diary.py
from fastapi import APIRouter, Depends, HTTPException, status, Path, UploadFile, File, Form
from sqlalchemy.orm import Session
from datetime import date, datetime, timedelta
from typing import List, Dict, Any, Optional
from PIL import Image

import os
import uuid
import shutil
import locale
import io
import base64
import random
import re

from ..models.user import User 
from ..models.diary import Diary 
from .. import auth
from ..schemas import diarySchema, userSchema
from ..database import get_db
from ..service import nlp_service, chatbot_service
import calendar

from ..config.templates import (
    INTRO_TEMPLATES, 
    WARMTH_TEMPLATES,
)

UPLOAD_DIR = os.getenv("UPLOAD_DIR", "app/images")
EMOJI_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "emoji")

try:
    os.makedirs(UPLOAD_DIR, exist_ok=True)
except FileExistsError:
    pass

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

## 감정 중요도 가중치 
EMOTION_WEIGHTS = {
    "Angry": -3.0, # 가장 부정
    "Fear": -4.0,
    "Sad": -5.0,
    "Happy": 5.0,  # 가장 긍정
    "Tender": 3.0,
    "Neutral": 1.0, # 중립
}

def convert_png_to_webp(filename: str) -> str:
    png_path = os.path.join(EMOJI_DIR, filename)
    webp_filename = filename.replace(".png", ".webp")
    webp_path = os.path.join(EMOJI_DIR, webp_filename)
    
    if os.path.exists(webp_path):
        return webp_filename
    
    img = Image.open(png_path).convert("RGBA")
    img.save(webp_path, "WEBP", lossless=True, quality=100)
    
    return webp_filename

## helper function
def create_diary_response(diary: Diary, user_name: str) -> dict:
    
    if diary.image_url: ## 사용자가 이미지를 첨부했을 경우
        primary_url = diary.image_url
    else: ## 이미지를 첨부하지 않았을 경우
        primary_url = f"/static/emoji/{diary.emotion_emoji}"
    
    ## 감정 점수 (0~100) 변환
    emotion_score_100 = round(diary.emotion_score * 100, 1)
    
    return {
        "id": diary.id,
        "user_id": diary.user_id,
        "user_name": user_name,
        "diary_date": diary.diary_date,
        "content": diary.content,
        "image_url": diary.image_url,
        
        "primary_image_url": primary_url, ## 최종 이미지
        "emotion_score": emotion_score_100, ## 최대 100점으로 변환한 감정 점수
        "emotion_emoji": diary.emotion_emoji,
        "emotion_label": diary.emotion_label,
        "overall_emotion_score": diary.overall_emotion_score,
        "ai_comment": diary.ai_comment,
        
        "created_at": diary.created_at,
    }
    
## ai봇 코멘트 생성
def create_ai_response(content: str, user_name: str, emotion_label: str) -> str:
    ai_comment_raw = f"오늘 {user_name}님은 여러가지 감정이 섞인 하루를 보냈군요"
    
    try:
        cleaned_content = re.sub(r'[^\w\s\.\,\!\?]', '', content)
        cleaned_content = ' '.join(cleaned_content.split()).strip()
        
        ai_comment_raw = chatbot_service.generate_comment(cleaned_content)
        
        intro_template_list = list(INTRO_TEMPLATES)
        selected_intro_template = random.choice(intro_template_list)
        intro_phrase = f"{user_name}{selected_intro_template}"
        
        emotion_key = emotion_label
        warmth_templates = WARMTH_TEMPLATES.get(emotion_key, WARMTH_TEMPLATES["Natural"])
        warmth_phrase = random.choice(warmth_templates)
        
        final_comment = (
            f"{intro_phrase} {ai_comment_raw} {warmth_phrase}"
        )
        
        return final_comment
        
    except Exception as e:
        # AI 챗봇 서비스 실패 시 기본 코멘트 반환
        print(f"Chatbot Service Failed: {e}")
        return ai_comment_raw
    

## 사용자 감정 점수 계산 helper function (시간 가중치 적용)
def calculate_emotion_score(diaries: List[Any], weights: Dict[str, float]) -> float:

    current_score = 100.0  # 심리 건강 기준점 
    
    if not diaries:
        return current_score 
    
    DAYS_WINDOW = 14 
    # 일기가 최신순으로 정렬되어 있다고 가정
    today = date.today()
    
    # 2. 총 일기 수 
    total_cnt = len(diaries)
    
    # 3. 최대/최소 변동 폭 설정
    MAX_SCORE_CHANGE_PER_DIARY = 5.0 
    MAX_TOTAL_CHANGE = total_cnt * MAX_SCORE_CHANGE_PER_DIARY 
    
    # 4. 점수 조정 누적
    total_adjustment = 0.0
    
    for diary in diaries:
        label = diary.emotion_label
        
        weight = weights.get(label) 
        
        if weight is not None:
            
            days_ago = (today - diary.diary_date).days
            
            # 최근일수록 1.0에 가깝고, 14일 전일수록 0.1(최소값)에 가까워짐
            decay_factor = max(0.1, (DAYS_WINDOW - days_ago) / DAYS_WINDOW)
            
            # 4-2. 조정 값 계산: 시간 가중치 적용
            # 조정 값: (가중치 * 감정 확률) * 시간 가중치
            adjustment_value = (weight * diary.emotion_score) * decay_factor
            total_adjustment += adjustment_value
            
    # 5. 최대/최소 변동 폭 적용하여 최종 점수 계산 
    if abs(total_adjustment) > MAX_TOTAL_CHANGE:
        if total_adjustment > 0:
            final_adjustment = MAX_TOTAL_CHANGE
        else:
            final_adjustment = -MAX_TOTAL_CHANGE
    else:
        final_adjustment = total_adjustment
        
    # 시작 점수에 최종 조정 값 반영
    final_score = current_score + final_adjustment
    
    # 6. 최종 점수를 0점에서 100점 사이로 제한 및 반올림
    user_emotion_score = round(max(0.0, min(100.0, final_score)), 1)
    
    return user_emotion_score
    
# 전체 일기 조회
@router.get("/main/{monthly_year}", response_model=diarySchema.MainPageResponse)
def get_all_diaries(
    monthly_year: str = Path(..., description="조회 날짜(YYYY-MM)", examples=["2025-11"]),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    user_id = current_user.id
    today = date.today()
    two_weeks = today - timedelta(days=14)
    
    try:
        current_year = int(monthly_year.split('-')[0])
        current_month = int(monthly_year.split('-')[1])
    except:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="날짜 형식이 유효하지 않습니다.(YYYY-MM)")
    
    start_of_month = date(current_year, current_month, 1)
    end_of_month = date(current_year, current_month, calendar.monthrange(current_year, current_month)[1])
    
    ## 영어 월 이름 계산
    target_date = date(current_year, current_month, 1)
    monthly_name_en = target_date.strftime("%B")
   
    ## 감정 점수 계산 용 일기 데이터 조회 (최근 이주 이내 데이터)
    recent_diaries = db.query(Diary).filter(Diary.user_id == user_id, Diary.diary_date >= two_weeks)\
        .order_by(Diary.diary_date.desc()).all()
       
    user_emotion_score = calculate_emotion_score(diaries=recent_diaries, weights=EMOTION_WEIGHTS)

    ## 달력 표시용 데이터
    all_diaries = db.query(Diary).filter(Diary.user_id == user_id,
                                         Diary.diary_date >= start_of_month,
                                         Diary.diary_date <= end_of_month).order_by(Diary.diary_date.asc()).all()

    calendar_diaries = []

    for entry in all_diaries:
        web_name = convert_png_to_webp(entry.emotion_emoji)
        calendar_diaries.append(diarySchema.CalendarResponse(
            id=entry.id,
            diary_date=entry.diary_date,
            emotion_emoji=f"/static/emoji/{web_name}"
        ))
        
    return {
        "monthly_year": monthly_year,
        "monthly_name_en": monthly_name_en,
        "user_emotion_score": user_emotion_score,
        "diaries": calendar_diaries
    }
    
# 일기 Create
@router.post("/new", response_model=diarySchema.DiaryResponse, status_code=status.HTTP_201_CREATED)
def create_diary(
    diary_date: date = Form(..., description="일기 작성 날짜(YYYY-MM-DD)", example="2025-11-13"),
    content: str = Form(..., max_length=100, description="일기 내용(최대 100자)"),
    image_file: Optional[UploadFile] = File(None, description="첨부 이미지 파일"), 
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user) ## JWT 인증 적용
):
    user_name = current_user.user_name
    ## 이미지 파일 처리
    uploaded_image_url: Optional[str] = None
    if image_file and image_file.filename:
        try:
            # 사용자별 directory 생성
            user_upload_dir = os.path.join(UPLOAD_DIR, current_user.id)
            os.makedirs(user_upload_dir, exist_ok=True)
            
            # 파일 확장자 확인 및 새 파일 이름 생성 (UUID 사용)
            file_extension = os.path.splitext(image_file.filename)[1]
            new_filename = str(uuid.uuid4()) + file_extension
            file_path = os.path.join(user_upload_dir, new_filename)
            
            # 파일 저장
            with open(file_path, "wb") as buffer:
                shutil.copyfileobj(image_file.file, buffer)
            
            # 프론트에서 접근 가능한 URL 생성
            uploaded_image_url = f"/static/images/{current_user.id}/{new_filename}"
            
        except Exception as e:
            print(f"ERROR: Image file saving failed: {e}")
            raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="이미지 저장 실패")
        finally:
            image_file.file.close() # 파일 스트림 닫기
    
    default_overall_emotion_score: Dict[str, float] = {
        label: 0.0 for label, _ in nlp_service.EMOTION_LABELS.values()
    }
    
    ## NLP/AI봇 실패 시 사용할 기본값 정의
    analysis_result = {
        'emotion_score': 0.0,
        'emotion_emoji': "default.png",
        'emotion_label': "Neutral",
        'overall_emotion_score': default_overall_emotion_score,
    }
    
    ai_comment_text = "오늘 너는 여러가지 감정이 섞인 하루를 보냈구나"
    
    # FIX: NLP 서비스 예외 처리 및 감정 점수 임계값 적용
    try:
        raw_analysis = nlp_service.get_emotion_analysis(content)
        
        ## DB 저장용 전체 감정 점수
        analysis_result['overall_emotion_score'] = raw_analysis['overall_emotion_score']
            
        ## AI 코멘트 생성
        ai_comment_text = create_ai_response(content, user_name, raw_analysis['emotion_label'])
        
    except Exception as e:
        print(f"NLP/Chatbot Service Failed: {e}")
        pass
        ## 실패 시 ai_comment_text와 analysis_result는 기본값 유지
    
    ## DB 객체 생성 및 저장
    new_diary = Diary(
        user_id=current_user.id,
        
        diary_date=diary_date,
        content=content,
        image_url=uploaded_image_url,
        
        ## 감정분석결과 저장
        emotion_score=raw_analysis['emotion_score'],
        emotion_emoji=raw_analysis['emotion_emoji'],
        emotion_label=raw_analysis['emotion_label'],
        overall_emotion_score=raw_analysis['overall_emotion_score'],
        
        ## AI봇 코멘트 결과
        ai_comment=ai_comment_text
    )
    
    db.add(new_diary)
    db.commit()
    db.refresh(new_diary)
    
    full_data = create_diary_response(new_diary, user_name=current_user.user_name) 
    del full_data['user_name'] 
    return diarySchema.DiaryResponse(**full_data)

## 특정 일기 상세 조회 
@router.get("/detail/{id}", response_model=diarySchema.DiaryDetailResponse)
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

    full_data = create_diary_response(diary, user_name=current_user.user_name)
    return diarySchema.DiaryDetailResponse(**full_data)

## 특정 일기 수정
@router.put("/modify/{id}", response_model=diarySchema.DiaryDetailResponse)
def update_diary(
    id: str,
    content: Optional[str] = Form(None, max_length=100, description="일기 내용 수정"),
    image_file: Optional[UploadFile] = File(None, description="첨부 이미지 파일"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    user_name = current_user.user_name
    diary_query = db.query(Diary).filter(
        Diary.user_id == current_user.id,
        Diary.id == id
    )
    diary = diary_query.first()
    
    if not diary:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"ID {id}에 해당하는 일기를 찾을 수 없습니다.")
    
    ## 이미지 파일 처리
    uploaded_image_url: Optional[str] = diary.image_url
    
    if image_file and image_file.filename:
        ## 새 이미지가 업로드된 경우: 새 파일 저장 및 URL 업데이트
        try:
            user_upload_dir = os.path.join(UPLOAD_DIR, current_user.id)
            os.makedirs(user_upload_dir, exist_ok=True)
            
            file_extension = os.path.splitext(image_file.filename)[1]
            new_filename = str(uuid.uuid4()) + file_extension
            file_path = os.path.join(user_upload_dir, new_filename)
            
            with open(file_path, "wb") as buffer:
                shutil.copyfileobj(image_file.file, buffer)
            
            uploaded_image_url = f"/static/images/{current_user.id}/{new_filename}"
            
        except Exception as e:
            print(f"ERROR: Image file saving failed during update: {e}")
            raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="이미지 수정 저장 실패")
        finally:
            image_file.file.close()
    
    ## content가 제공되지 않으면 기존 내용을 사용하고 NLP 분석을 건너뛰기
    updated_content = content if content is not None else diary.content
    ## 내용이 변경되었을 때만 NLP/AI 분석 결과를 업데이트
    content_changed = (content is not None) and (content != diary.content)
    
    default_overall_emotion_score: Dict[str, float] = {
        label: 0.0 for label, _ in nlp_service.EMOTION_LABELS.values()
    }
    
    ## NLP/AI봇 실패 시 사용할 기본값 정의
    analysis_result = {
        'emotion_score': diary.emotion_score or 0.0,
        'emotion_emoji': diary.emotion_emoji or "default.png",
        'emotion_label': diary.emotion_label or "Neutral",
        'overall_emotion_score': diary.overall_emotion_score or default_overall_emotion_score,
    }
    ai_comment_text = diary.ai_comment or f"오늘 {user_name}님은 여러가지 감정이 섞인 하루를 보냈군요"
    
    if content_changed:
        try:
            raw_analysis = nlp_service.get_emotion_analysis(updated_content)
            
            analysis_result['overall_emotion_score'] = raw_analysis['overall_emotion_score']
            analysis_result['emotion_score'] = raw_analysis['emotion_score']
            analysis_result['emotion_emoji'] = raw_analysis['emotion_emoji']
            analysis_result['emotion_label'] = raw_analysis['emotion_label']
            
            ## AI 코멘트 재생성
            ai_comment_text = create_ai_response(updated_content, user_name, analysis_result['emotion_label'])

        except Exception as e:
            print(f"NLP/Chatbot Service Failed: {e}")
            pass
    
    update_payload = {
        ## content가 제공되었을 때만 업데이트
        "content": updated_content if content is not None else diary.content,
        ## 이미지 URL은 항상 업데이트 (새 파일이 없으면 기존 URL로 유지됨)
        "image_url": uploaded_image_url,
        "emotion_score": analysis_result['emotion_score'],
        "emotion_emoji": analysis_result['emotion_emoji'],
        "emotion_label": analysis_result['emotion_label'],
        "overall_emotion_score": analysis_result['overall_emotion_score'],
        "ai_comment": ai_comment_text,
    }
    diary_query.update(update_payload, synchronize_session=False)
    db.commit()
    db.refresh(diary)
    
    full_data = create_diary_response(diary, user_name=current_user.user_name)
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
    delete_count = db.query(Diary).filter(
        Diary.user_id == current_user.id,
        Diary.id == id
    ).delete(synchronize_session=False) 
    
    if delete_count == 0:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, 
            detail=f"ID {id}에 해당하는 일기를 찾을 수 없거나 삭제 권한이 없습니다."
        )

    db.commit()
    
    return