#backend/app/positiveSchema.py

from pydantic import BaseModel, Field
from datetime import date, datetime
from typing import Optional, List

## 긍정 질문 가져오기
class PositiveQuestionResponse(BaseModel):
    id: str = Field(..., description="긍정질문 UUID")
    question_number: int = Field(..., description="긍정질문 번호")
    text: str = Field(..., description="긍정 질문 내용")
    
    class Config:
        from_attributes = True

class CurrentQuestionResponse(BaseModel):
    question: Optional[PositiveQuestionResponse] = Field(None, description="제공할 긍정 질문")
    # last_answered_date: Optional[date] = Field(None, description="마지막 답변 날짜")
    
## 긍정질문 답변
class AnswerCreate(BaseModel):
    question_id: str = Field(..., description="긍정질문 UUID")
    answer: str = Field(..., description="사용자 답변")
  
class AnswerResponse(BaseModel):
    id: str = Field(..., description="긍정일기UUID")
    diary_date: date = Field(..., description="답변 작성 날짜")
    answer: str = Field(..., description="사용자 답변")
    question_id: str = Field(..., description="긍정질문 UUID")
    
    class Config:
        from_attributes = True
        
## 긍정질문 답변 수정
class UpdateAnswerCreate(BaseModel):
    answer: str = Field(..., description="사용자 답변")
    
## 특정 긍정 일기 상세 조회
class AnswerDetailResponse(BaseModel):
    id: str = Field(..., description="긍정일기UUID")
    question_number: int = Field(..., description="질문 번호")
    text: str = Field(..., description="긍정 질문 내용")
    answer: str = Field(..., description="입력된 답변")
    
    class Config:
        from_attributes = True
        

## 1. 과거 긍정일기 질문
class PastAnswerItem(BaseModel):
    id: str = Field(..., description="긍정일기UUID")
    question_number: int = Field(..., description="질문 번호")
    text: str = Field(..., description="긍정 질문 내용")
    
    class Config:
        from_attributes = True

class PastAnswerResponse(BaseModel):
    past_answer: List[PastAnswerItem]
    
## 긍정일기 페이지 통합 응답
class PositivePageResponse(BaseModel):
    current_question: CurrentQuestionResponse = Field(..., description="새로 생긴 긍정질문")
    past_answers: List[PastAnswerItem] = Field(..., description="이전 긍정질문들")

    
    

