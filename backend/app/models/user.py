#backend/app/models/user.py

from datetime import datetime, timezone
from sqlalchemy import Column, String, Date, Enum, Text, DateTime
from sqlalchemy.dialects.mysql import CHAR
from sqlalchemy.orm import relationship
from ..database import Base
import uuid

class User(Base):
    __tablename__ = "TB_user"
    
    ## Primary Key로 UUID 사용
    id = Column(CHAR(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    
    # UI 입력 받는 필드
    user_name = Column(String(50), nullable=False, comment="사용자 이름")
    user_id = Column(String(50), unique=True, index=True, nullable=False, comment="로그인 아이디")
    user_pwd = Column(String(255), nullable=False)
    birth_date = Column(Date, nullable=False)
    gender = Column(Enum('M', 'F'), name='gender_enum', nullable=False)
    
    created_at = Column(
        DateTime, 
         default=lambda: datetime.now(timezone.utc),    # 레코드 생성 시 UTC 기준으로 현재 시각 자동 입력
        nullable=False
    )
    
    diaries = relationship("Diary", back_populates="user")
    positive_diaries = relationship("PositiveDiary", back_populates="user")
    
    def __repr__(self):
        return f"<User(id='{self.id}', user_id='{self.user_id}', user_name='{self.user_name}')>"
