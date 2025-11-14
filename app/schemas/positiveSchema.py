#backend/app/positiveSchema.py

from pydantic import BaseModel, Field
from datetime import date, datetime
from typing import Optional

## 긍정 질문 가져오기
class PositiveQuestionResponse(BaseModel):
    id: str = Field(..., description="질문 uuid")
    question_number: int = Field(..., description="질문 번호")
    text: str = Field(..., description="긍정 질문 내용")
    
    class Config:
        from_attributes = True

class CurrentQuestionResponse(BaseModel):
    question: Optional[PositiveQuestionResponse] = Field(None, description="제공할 긍정 질문")
    last_answered_date: Optional[date] = Field(None, description="마지막 답변 날짜")
    
## 긍정질문 답변
class AnswerCreate(BaseModel):
    question_id: str = Field(..., description="답변하려는 질문 UUID")
    answer: str = Field(..., description="사용자 답변")

class AnswerResponse(BaseModel):
    id: str = Field(..., description="긍정질문답변 UUID")
    diary_date: date = Field(..., description="답변 작성 날짜")
    answer: str = Field(..., description="사용자 답변")
    question_id: str = Field(..., description="긍정질문 UUID")
    
    class Config:
        from_attributes = True

