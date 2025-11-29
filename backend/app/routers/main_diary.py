# backend/router/main_diary.py
from fastapi import APIRouter, Depends, HTTPException, status, Path, UploadFile, File, Form
from sqlalchemy.orm import Session
from datetime import date, datetime, timedelta
from typing import List, Dict, Any, Optional

import os
import uuid
import shutil
import locale

from ..models.user import User 
from ..models.diary import Diary 
from .. import auth
from ..schemas import diarySchema, userSchema
from ..database import get_db
from ..service import nlp_service, chatbot_service
import calendar
import base64 
import io


## 1. 환경 변수에서 경로를 읽어옵니다. 
TEMP_DIR_RELATIVE = os.getenv("PYTHON_TEMP_DIR", "app/temp_data")

## 2. 절대 경로를 생성합니다. 
TEMP_DIR = os.path.join(os.getcwd(), TEMP_DIR_RELATIVE) 

## 3. 폴더 생성 및 환경 변수 설정
os.makedirs(TEMP_DIR, exist_ok=True)

# Python 프로세스가 임시 파일 저장 경로를 D 드라이브로 인식하도록 환경 변수 설정
os.environ['TMP'] = TEMP_DIR
os.environ['TEMP'] = TEMP_DIR

## 파일 경로 지정 : (image 업로드 경로)
UPLOAD_DIR = os.path.join(os.getcwd(), "app", "images")
os.makedirs(UPLOAD_DIR, exist_ok=True)
EMOJI_DIR = os.path.join(os.getcwd(), "app", "emoji")

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
    "Angry": -4, # 가장 부정
    "Fear": -2,
    "Sad": -3,
    "Happy": 4,  # 가장 긍정
    "Tender": 2,
    "Neutral": 1, # 중립
}

def encode_emoji_to_base64(filename: str) -> str:
    """
    이모지 파일명을 받아 파일을 읽고 Base64 문자열로 인코딩합니다.
    """
    file_path = os.path.join(EMOJI_DIR, filename)
    
    if not os.path.exists(file_path):
        # 파일이 없을 경우, 오류를 피하기 위해 빈 문자열 반환 (프론트엔드에서 처리)
        print(f"WARNING: Emoji file not found at {file_path}. Using empty Base64 string.")
        return "" 
    
    try:
        with open(file_path, "rb") as image_file:
            # Base64 인코딩
            encoded_string = base64.b64encode(image_file.read()).decode('utf-8')
            # Flutter에서 Image.memory를 위해 데이터 URI 헤더 없이 데이터만 반환
            return encoded_string
    except Exception as e:
        print(f"ERROR: Failed to encode image {filename}: {e}")
        return ""

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

## 사용자 감정 점수 계산 helper function  
def calculate_emotion_score(diaries: List[Diary], weights: Dict[str, int]) -> float:

    total_score = 0
    total_cnt = len(diaries)

    if total_cnt == 0:
        return 0.0

    ## 총 점수 계산
    for diary in diaries:
        label = diary.emotion_label
        weight = weights.get(label)
        if weight is not None:
            ## diary.emotion_score는 0.0 ~ 1.0 사이의 확률 값
            total_score += weight * diary.emotion_score
            
    max_weight = max(weights.values())
    min_weight = min(weights.values())
    
    ## 정규화
    min_possible_score = total_cnt * min_weight
    max_possible_score = total_cnt * max_weight
    score_range = max_possible_score - min_possible_score
    
    if score_range == 0:
        user_emotion_score = 50.0
    else:
        ## 0 ~ 100점 스케일로 정규화
        normalized_score = (total_score - min_possible_score) / score_range
        user_emotion_score = round(max(0.0, min(1.0, normalized_score)) * 100, 1)
        
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
    thirty_days = today - timedelta(days=30)
    
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
   
    ## 감정 점수 계산 용 일기 데이터 조회 (최근 30일 이내 데이터)
    recent_diaries = db.query(Diary).filter(Diary.user_id == user_id, Diary.diary_date >= thirty_days)\
        .order_by(Diary.diary_date.desc()).all()
       
    user_emotion_score = calculate_emotion_score(diaries=recent_diaries, weights=EMOTION_WEIGHTS)

    ## 달력 표시용 데이터
    all_diaries = db.query(Diary).filter(Diary.user_id == user_id,
                                         Diary.diary_date >= start_of_month,
                                         Diary.diary_date <= end_of_month).order_by(Diary.diary_date.asc()).all()

    calendar_diaries = []

    for entry in all_diaries:
        base64_data = encode_emoji_to_base64(entry.emotion_emoji)
        calendar_diaries.append(diarySchema.CalendarResponse(
            id=entry.id,
            diary_date=entry.diary_date,
            emotion_emoji=base64_data
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
        
        ## 감정 점수가 임계값 미만일 경우, Neutral로 강제 처리 
        if raw_analysis['emotion_score'] < EMOTION_SCORE_THRESHOLD:
            analysis_result['emotion_label'] = "Neutral"
            analysis_result['emotion_emoji'] = "default.png" 
            analysis_result['emotion_score'] = raw_analysis['emotion_score'] ## 점수는 유지
        else:
            analysis_result = raw_analysis
            
        ## AI 코멘트 생성
        ai_comment_text = chatbot_service.generate_comment(content, analysis_result['emotion_label'])
        
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
        emotion_score=analysis_result['emotion_score'],
        emotion_emoji=analysis_result['emotion_emoji'],
        emotion_label=analysis_result['emotion_label'],
        overall_emotion_score=analysis_result['overall_emotion_score'],
        
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
    ai_comment_text = diary.ai_comment or "오늘 너는 여러가지 감정이 섞인 하루를 보냈구나"
    
    if content_changed:
        try:
            raw_analysis = nlp_service.get_emotion_analysis(updated_content)
            
            analysis_result['overall_emotion_score'] = raw_analysis['overall_emotion_score']

            if raw_analysis['emotion_score'] >= EMOTION_SCORE_THRESHOLD:
                analysis_result['emotion_score'] = raw_analysis['emotion_score']
                analysis_result['emotion_emoji'] = raw_analysis['emotion_emoji']
                analysis_result['emotion_label'] = raw_analysis['emotion_label']
            else:
                analysis_result['emotion_score'] = raw_analysis['emotion_score']
                analysis_result['emotion_label'] = "Neutral"
                analysis_result['emotion_emoji'] = "default.png"

            ## AI 코멘트 재생성
            ai_comment_text = chatbot_service.generate_comment(updated_content, analysis_result['emotion_label'])

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