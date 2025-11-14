# backend/router/positive_diary.py

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import date, datetime, timedelta
from typing import List, Dict, Any

from ..models.user import User
from ..models.positiveQuestion import PositiveQuestion
from ..models.positiveDiary import PositiveDiary
from .. import auth
from ..schemas import positiveSchema
from ..database import get_db
from ..routers.main_diary import get_current_active_user

router = APIRouter(
    prefix="/api/positive",
    tags=["Positive Diary"]
)
# ###### 나중에 지워야함#######
# ## JWT 토큰 검증 후 DB에서 User 객체 가져옴
# def get_current_active_user(user_id: str = Depends(auth.get_current_user), db: Session = Depends(get_db)):
#     user = db.query(User).filter(User.id == user_id).first()
#     if user is None:
#         raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="사용자를 찾을 수 없습니다.")
#     return user

## 긍정 질문 가져오기
@router.get("/question", response_model=positiveSchema.CurrentQuestionResponse)
def get_current_question(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    user_id = current_user.id
    today = date.today()
    
    ## 마지막 답변 기록 조회
    last_entry = db.query(PositiveDiary)\
        .filter(PositiveDiary.user_id == user_id)\
            .order_by(PositiveDiary.diary_date.desc())\
                .first()
    last_answered_date = None
    last_question_number = 0
    
    if last_entry:
        last_answered_date = last_entry.diary_date
        ## 마지막 답변 질문 객체 찾기
        last_question = db.query(PositiveQuestion).filter(PositiveQuestion.id == last_entry.question_id).first()
        if last_question:
            last_question_number = last_question.question_number
    
    ## 다음 질문 번호 결정
    next_question_number = last_question_number + 1
    
    ## 시간 제약 : 다음 질문은 답변일 기준 다음 날에 제공되도록
    can_get_new_question = True
    if last_answered_date:
        if today <= last_answered_date: ## 오늘 날짜가 마지막 답변 날짜보다 커야 새로운 질문이 제공됨
            can_get_new_question = False
    
    ## 다음 질문 조회
    next_question = db.query(PositiveQuestion)\
        .filter(PositiveQuestion.question_number == next_question_number).first()
        
    question_to_return = None
    
    if next_question and can_get_new_question:
        question_to_return = next_question
        
    return {
        "question": question_to_return
    }
    
## 긍정 질문 작성 CREATE
@router.post("/answer", response_model=positiveSchema.AnswerResponse, status_code=status.HTTP_201_CREATED)
def post_answer(
    answer_data: positiveSchema.AnswerCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    user_id = current_user.id
    today = date.today()
    
    ## 질문 ID 유효성 및 존재 여부
    question = db.query(PositiveQuestion).filter(PositiveQuestion.id == answer_data.question_id).first()
    if not question:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="유효하지 않는 질문ID")
    
    ## 이전 질문 답변 완료 여부 및 순서 확인
    last_entry = db.query(PositiveDiary).filter(PositiveDiary.user_id== user_id)\
        .order_by(PositiveDiary.diary_date.desc()).first()
    last_q_num = 0
    if last_entry:
        last_q = db.query(PositiveQuestion).filter(PositiveQuestion.id == last_entry.question_id).first()
        if last_q:
            last_q_num = last_q.question_number
    
    ## 사용자 답변 긍정 질문 번호
    current_q_num = question.question_number
    
    ## 규칙 : 다음 순서의 질문이거나 첫 질문이어야만 답변 가능
    if current_q_num != last_q_num + 1 and current_q_num != 1:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="이전 질문에 순서대로 답변해야 합니다.")
    ## 중복 답변 방지
    today_entry = db.query(PositiveDiary).filter(PositiveDiary.user_id == user_id,
                                                 PositiveDiary.diary_date == today).first()
    if today_entry:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="오늘은 이미 긍정 질문에 답변했습니다.")
    
    new_answer = PositiveDiary(
        user_id=user_id,
        question_id=answer_data.question_id,
        diary_date=today,
        answer=answer_data.answer
    )
    
    db.add(new_answer)
    db.commit()
    db.refresh(new_answer)
    
    return new_answer
        
    