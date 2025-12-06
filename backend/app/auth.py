# backend/app/auth.py

from datetime import datetime, timedelta, timezone 
from typing import Optional
from jose import JWTError, jwt
from passlib.context import CryptContext
# from passlib.handlers.bcrypt import bcrypt
import os
from dotenv import load_dotenv
from fastapi import HTTPException, status, Depends, Security
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

load_dotenv()

## JWT 보안
SECRET_KEY = os.getenv("SECRET_KEY")
if not SECRET_KEY:
    raise ValueError("환경 변수 SECRET_KEY가 설정되어 있지 않습니다. .env 파일을 확인하세요.")

ALGORITHM = os.getenv("ALGORITHM", "HS256")
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", 120)) 

pwd_context = CryptContext(schemes=["pbkdf2_sha256"], deprecated="auto")
security = HTTPBearer()

def hash_password(password: str) -> str:
    return pwd_context.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:

    return pwd_context.verify(plain_password, hashed_password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    """
    user_id(UUID)를 포함한 JWT 생성
    """
    to_encode = data.copy()

    # 만료 시간
    expire = datetime.now(timezone.utc) + (
        expires_delta if expires_delta else timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    )
    to_encode.update({"exp": expire})

    # JWT 표준 규약 sub = user_id
    to_encode["sub"] = str(data.get("id"))

    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def get_current_user(credentials: HTTPAuthorizationCredentials = Security(security)):
    """
    Authorization: Bearer <token> 에 담긴 JWT 검증하고 user_id(UUID) 추출
    """
    token = credentials.credentials

    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="인증 정보를 확인할 수 없거나 토큰이 만료되었습니다.",
        headers={"WWW-Authenticate": "Bearer"},
    )

    try:
        # 디코딩
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])

        # user_id
        user_id: str = payload.get("id")
        if user_id is None:
            raise credentials_exception

    except JWTError:
        raise credentials_exception

    return user_id