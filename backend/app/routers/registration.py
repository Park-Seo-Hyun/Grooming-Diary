# backend/app/router/registration.py
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from ..models.user import User 
from ..models.diary import Diary 
from ..models.positiveDiary import PositiveDiary
from .. import auth
from ..schemas import userSchema 
from ..database import get_db
# from fastapi.security import OAuth2PasswordBearer
from ..routers.main_diary import get_current_active_user

router = APIRouter(
    prefix="/auth", 
    tags=["auth"],
    responses={404:{"description": "Not found"}}
)

## 아이디 중복 확인
@router.get("/check_id", response_model=userSchema.IDCheckResponse)
def check_user_id(
    user_id: str = Query(..., description="확인할 사용자 로그인 아이디"),
    db: Session = Depends(get_db)
):
    db_user = db.query(User).filter(User.user_id == user_id).first()
    if db_user:
        return {
            "is_available": False,
            "message": "이미 사용 중인 아이디입니다."
        }
    else:
        return{
            "is_available": True,
            "message": "사용 가능한 아이디입니다."
        }

## 회원가입 API
@router.post("/register", response_model=userSchema.UserResponse, status_code=status.HTTP_201_CREATED)
def register(user_data: userSchema.UserCreate, db: Session = Depends(get_db)):
    # 1. 사용자 ID 중복 확인
    db_user = db.query(User).filter(User.user_id == user_data.user_id).first()
    if db_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="이미 존재하는 사용자 ID입니다."
        )   
    # 2.  비밀번호 해싱
    hashed_password = auth.hash_password(user_data.user_pwd)
    
    new_user = User(
        user_name=user_data.user_name,
        user_id=user_data.user_id,
        user_pwd=hashed_password,  # 해싱된 비밀번호 저장
        birth_date=user_data.birth_date,
        gender=user_data.gender
    )
    
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    return new_user

## 로그인 API
@router.post("/login", response_model=userSchema.LoginSuccess)
def login(user_credentials: userSchema.UserLogin, db: Session = Depends(get_db)):
    
    user = db.query(User).filter(User.user_id == user_credentials.user_id).first()


    if not user or not auth.verify_password(user_credentials.user_pwd, user.user_pwd):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="아이디 또는 비밀번호가 일치하지 않습니다.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    access_token = auth.create_access_token(
        data={"id": user.id}
    )
    return {
        "message": "로그인 성공",
        "user_id": user.user_id,
        "user_name": user.user_name,
        "token": { 
            "access_token": access_token,
            "token_type": "bearer"
        }
    }
    
## 로그아웃 API
@router.get("/logout", response_model=userSchema.LogoutSuccess)
def logout():
    return {"message": "로그아웃 성공"}

## 회원탈퇴 
@router.delete("/unsubscribe", status_code=status.HTTP_204_NO_CONTENT)
def withdrawal_of_membership(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    user_id = current_user.user_id
    
    try:
        db.query(Diary).filter(Diary.user_id == user_id).delete(synchronize_session=False)
        db.query(PositiveDiary).filter(PositiveDiary.user_id == user_id).delete(synchronize_session=False)
        
        user_delete = db.query(User).filter(User.user_id == user_id)
        
        if not user_delete.first():
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="사용자를 찾을 수 없습니다.")
        
        user_delete.delete(synchronize_session=False)
        
        db.commit()
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"회원 탈퇴 중 데이터베이스 오류 발생: {e}")

    return
    
