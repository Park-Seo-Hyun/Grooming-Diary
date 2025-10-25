# backend/app/database.py

from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base
from sqlalchemy.orm import sessionmaker
# from decouple import Config # 필요 없음
# import os # 필요 없음

# 🌟 DATABASE_URL 변수에 값을 직접 할당하여 .env 파일 로드 문제(decouple 오류)를 우회합니다.
DATABASE_URL = "mysql+mysqlconnector://groom_user:0000@localhost:3306/groom_db"


# 데이터베이스 연결 엔진 생성
# pool_pre_ping=True 옵션을 추가하여 연결 안정성을 높입니다.
engine = create_engine(DATABASE_URL, pool_pre_ping=True)

# 데이터베이스 세션 생성기(sessionmaker) 생성
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Base는 모든 모델이 상속받는 기본 클래스입니다.
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()