# backend/app/app.py

from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from .routers import registration, positive_diary, main_diary, emotion_graph, mypage

from fastapi.middleware.cors import CORSMiddleware
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import Response

import os

async def add_cache_control_header(request, call_next):
    response = await call_next(request)
    
    # 정적 파일 경로 확인 (/static/emoji/ 또는 /static/images/)
    if request.url.path.startswith("/static/emoji/"):
        
        # 캐싱 헤더 적용
        response.headers["Cache-Control"] = "public, max-age=31536000, immutable"
        
    return response


app = FastAPI()

app.add_middleware(BaseHTTPMiddleware, dispatch=add_cache_control_header)

origins = ["*"]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

CURRENT_DIR = os.path.dirname(os.path.abspath(__file__)) 
EMOJI_STATIC_DIR = os.path.join(CURRENT_DIR, "emoji")
IMAGES_STATIC_DIR = os.path.join(CURRENT_DIR, "images")

app.mount("/static/emoji", StaticFiles(directory=EMOJI_STATIC_DIR), name="static_emoji")
app.mount("/static/images", StaticFiles(directory=IMAGES_STATIC_DIR), name="static_images")



app.include_router(registration.router)
app.include_router(main_diary.router)
app.include_router(positive_diary.router)
app.include_router(emotion_graph.router)
app.include_router(mypage.router)

@app.get("/")
def read_root():
    return {"Hello": "World"}
