#backend/app/models/positiveQuestion.py

from sqlalchemy import Column, Integer, Text, Identity
from sqlalchemy.dialects.mysql import CHAR
from ..database import Base
from sqlalchemy.orm import relationship
import uuid

class PositiveQuestion(Base):
    __tablename__="TB_positive_question"
    
    id = Column(CHAR(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    
    question_number = Column(
        Integer, 
        Identity(start=1, increment=1), 
        unique=True, 
        nullable=False
    )
    
    text = Column(Text, nullable=False)
    
    
    positive_diary_entries = relationship("PositiveDiary", back_populates="question")
    
    def __repr__(self):
        return f"<PositiveQuestion(number={self.question_number}, id='{self.id}')>"