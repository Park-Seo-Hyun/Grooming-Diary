#backend/app/models/positiveDiary.py

from sqlalchemy import Column, Date, Text, ForeignKey
from sqlalchemy.dialects.mysql import CHAR
from sqlalchemy.orm import relationship
from ..database import Base
import uuid

class PositiveDiary(Base):
    __tablename__ = "TB_positive_diary"
    
    id = Column(CHAR(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    
    user_id = Column(CHAR(36), ForeignKey("TB_user.id"), nullable=False)
    question_id = Column(CHAR(36), ForeignKey("TB_positive_question.id"), nullable=False)
    
    answer = Column(Text, nullable=False)
    
    diary_date = Column(Date, unique=True, nullable=False)
    
    user = relationship("User", back_populates="positive_diaries")
    question = relationship("PositiveQuestion", back_populates="positive_diary_entries")
    
    def __repr__(self):
        return f"<PositiveDiary(id='{self.id}', user_id='{self.user_id}', date='{self.diary_date}')>"
    