#backend/app/schemas.py

from pydantic import BaseModel, Field
from datetime import date, datetime, timedelta

## 회원가입
class UserCreate(BaseModel):
    user_name: str = Field(..., description="사용자 이름")
    user_id: str = Field(..., description="사용자 로그인 아이디")
    user_pwd: str = Field(..., description="사용자가 설정할 비밀번호")
    birth_date: date = Field(..., description="사용자 생년월일 (YYYY-MM-DD 형식)")
    gender: str = Field(..., description="사용자 성별 ('M' 또는 'F')")
    
## 아이디 중복 확인
class IDCheckResponse(BaseModel):
    is_available: bool = Field(..., description="아이디 사용 가능 여부(True: 사용 가능)")
    message: str = Field(..., description="결과 메시지")

class UserResponse(BaseModel):
    id: str = Field(..., description="사용자 고유 ID (UUID)")
    user_id: str = Field(..., description="사용자 로그인 아이디")
    user_name: str = Field(..., description="사용자 이름")
    birth_date: date = Field(..., description="사용자 생년월일")
    gender: str = Field(..., description="사용자 성별")
    created_at: datetime = Field(..., description="계정 생성 시간 (UTC)")
    
    class Config:
        # SQLAlchemy ORM 객체를 Pydantic 모델로 변환할 수 있도록 설정
        from_attributes = True
        

## 로그인
class UserLogin(BaseModel):
    user_id: str = Field(..., description="로그인 아이디")
    user_pwd: str = Field(..., description="비밀번호")
    
class Token(BaseModel):
    access_token: str = Field(..., description="접근 토큰 (JWT)")
    token_type: str = Field("bearer", description="토큰 타입")

class LoginSuccess(BaseModel):
    message: str = Field(..., description="로그인 결과 메시지")
    user_id: str = Field(..., description="사용자 로그인 아이디")
    user_name: str = Field(..., description="사용자 이름")
    token: Token = Field(..., description="발급된 JWT 토큰 정보") 
    
# 로그아웃
class LogoutSuccess(BaseModel):
    message: str = Field("로그아웃 성공", description="로그아웃 성공 메시지")
    