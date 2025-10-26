#backend/app/auth.py

from datetime import datetime, timedelta, timezone 
from typing import Optional
from jose import JWTError, jwt
from passlib.context import CryptContext
from passlib.handlers.bcrypt import bcrypt
import os
from dotenv import load_dotenv
from fastapi import HTTPException, status, Depends
from fastapi.security import OAuth2PasswordBearer

load_dotenv()

SECRET_KEY = os.getenv("SECRET_KEY", "YOUR_SUPER_SECRET_KEY")
ALGORITHM = os.getenv("ALGORITHM", "HS256")
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", 60)) 

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login") 

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def hash_password(password: str) -> str:
    """
    비밀번호를 bcrypt 알고리즘으로 해싱하는 함수.
    :param password: 사용자가 입력한 평문 비밀번호
    :return: bcrypt로 해싱된 비밀번호 문자열
    """
    safe_password = password[:72]
    return pwd_context.hash(safe_password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """
    입력된 평문 비밀번호와 해싱된 비밀번호를 비교하는 함수.
    :param plain_password: 사용자가 입력한 평문 비밀번호
    :param hashed_password: 데이터베이스에 저장된 해싱된 비밀번호
    :return: 두 비밀번호가 일치하면 True, 그렇지 않으면 False
    """
    safe_plain_password = plain_password[:72]
    return pwd_context.verify(plain_password, hashed_password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    """
    주어진 데이터를 기반으로 JWT 액세스 토큰을 생성합니다.
    """
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        # 기본 만료 시간 적용
        expire = datetime.now(timezone.utc) + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    
    # 토큰의 payload에 만료 시간을 포함
    to_encode.update({"exp": expire, "sub": "access"})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def get_current_user(token: str = Depends(oauth2_scheme)):
    """
    JWT 토큰을 검증하고 토큰에 포함된 사용자 ID(UUID)를 추출합니다.
    이 함수는 보호된 API에 의존성 주입되어 사용됩니다.
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="인증 정보를 확인할 수 없거나 토큰이 만료되었습니다.",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        # 토큰 디코딩
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        
        # UUID로 저장된 사용자 ID (DB의 기본 키) 추출
        user_id: str = payload.get("id")
        if user_id is None:
            raise credentials_exception
            
    except JWTError:
        # JWTError(예: 만료, 변조 등) 발생 시 401 예외 발생
        raise credentials_exception
        
    return user_id