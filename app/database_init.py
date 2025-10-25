# backend/app/database_init__.py

from .database import engine, Base
# ORM 모델 가져오기
from .models.user import User
from .models.diary import Diary
from .models.positiveDiary import PositiveDiary
from .models.positiveQuestion import PositiveQuestion

import sys
import os

def create_tables():
    """정의된 ORM 모델을 기반으로 데이터베이스에 모든 테이블을 생성합니다."""
    
    # 3. Base 객체를 사용하여 테이블을 생성합니다. (models.Base.metadata 오류 해결)
    Base.metadata.create_all(bind=engine)

    # 작업 완료 메시지 출력
    print("테이블 생성 완료")


if __name__ == "__main__":
    create_tables()