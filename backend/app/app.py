# backend/app/app.py

from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from .routers import registration, positive_diary, main_diary, emotion_graph, mypage

import os


app = FastAPI()

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