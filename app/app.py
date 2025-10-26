#backend/app/app.py

from fastapi import FastAPI
from .routers import registration

app = FastAPI()
app.include_router(registration.router)

@app.get("/")
def read_root():
    return {"Hello": "World"}