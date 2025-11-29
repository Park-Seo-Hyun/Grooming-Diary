#backend/app/models/diary.py

from datetime import datetime, timezone
from sqlalchemy import Column, String, Date, Text, DateTime, Float, ForeignKey, JSON
from sqlalchemy.dialects.mysql import CHAR
from sqlalchemy.orm import relationship
from ..database import Base

import uuid

class Diary(Base):
    __tablename__="TB_diary"
    
    id = Column(CHAR(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    
    user_id = Column(CHAR(36), ForeignKey("TB_user.id"), nullable=False)
    
    diary_date = Column(Date, unique=True, nullable=False)
    content = Column(Text, nullable=False)
    image_url = Column(String(255), nullable=True)
    
    emotion_score = Column(Float, nullable=False)
    emotion_emoji = Column(String(255), nullable=False)
    emotion_label = Column(String(20), nullable=False)
    
    overall_emotion_score = Column(JSON, nullable=False) 

    
    ai_comment = Column(Text, nullable=False, comment="AI 봇이 일기에 대해 남긴 코멘트") 
    
    created_at = Column(
        DateTime, 
        default=lambda: datetime.now(timezone.utc),
        nullable=False
    )
    
    
    user = relationship("User", back_populates="diaries")
    
    def __repr__(self):
        return f"<Diary(id='{self.id}', user_id='{self.user_id}', date='{self.diary_date}')>"
    