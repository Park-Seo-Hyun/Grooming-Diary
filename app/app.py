# backend/app/app.py

from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from .routers import registration, positive_diary, main_diary, emotion_graph, mypage



app = FastAPI()

app.mount("/static/emoji", StaticFiles(directory="app/emoji"), name="static_emoji")
app.mount("/static/images", StaticFiles(directory="app/images"), name="static_images")

app.include_router(registration.router)
app.include_router(main_diary.router)
app.include_router(positive_diary.router)
app.include_router(emotion_graph.router)
app.include_router(mypage.router)

@app.get("/")
def read_root():
    return {"Hello": "World"}