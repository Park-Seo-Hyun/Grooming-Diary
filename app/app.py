#backend/app/app.py

from fastapi import FastAPI
from .routers import registration, positive_diary

app = FastAPI()
app.include_router(registration.router)
# app.include_router(main_diary.router) , main_diary
app.include_router(positive_diary.router)

@app.get("/")
def read_root():
    return {"Hello": "World"}