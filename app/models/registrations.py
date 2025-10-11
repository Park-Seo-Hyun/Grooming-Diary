#backend/app/models/registrations.py

from datetime import datetime, timezone
from sqlalchemy import Column, String, Date, Enum, Text, DateTime
from sqlalchemy.dialects.mysql import CHAR
from app.database import Base

import uuid

class Registraion(Base):
    __tablename__ = "TB_regist"
    
    ## Primary Key로 UUID 사용
    user_uuid = Column(CHAR(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    
    # UI 입력 받는 필드
    user_name = Column(String(50), nullable=False)
    user_id = Column(String(50), unique=True, index=True, nullable=False)
    user_pwd = Column(String(255), nullable=False)
    birth_date = Column(Date, nullable=False)
    gender = Column(Enum('M', 'F'), name='gender_enum', nullable=False)
    
    created_at = Column(
        DateTime, 
         default=lambda: datetime.now(timezone.utc),    # 레코드 생성 시 UTC 기준으로 현재 시각 자동 입력
        nullable=False
    )
