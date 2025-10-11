#backend/app/database.py

from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base
from sqlalchemy.orm import sessionmaker
from decouple import Config

# .env 파일에서 설정을 읽어오는 Config 객체 생성
config = Config(".env")

# .env 파일에서 DATABASE_URL 값을 가져오기
DATABASE_URL = config("DATABASE_URL")

# 데이터베이스 연결 엔진 생성
engine = create_engine(DATABASE_URL)

# 데이터베이스 세션 생성기(sessionmaker) 생성
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()