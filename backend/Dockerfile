FROM python:3.9-slim

ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
ENV UPLOAD_DIR /app/app/images

WORKDIR /app

RUN apt-get update && \
    apt-get install -y build-essential gcc curl libgfortran5 && \
    rm -rf /var/lib/apt/lists/*

COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

RUN pip install --upgrade python-jose

COPY backend/app/ai_model /app/app/ai_model

COPY backend/app /app/app
COPY backend/main.py . 

ENV LOCAL_MODEL_PATH="/app/app/ai_model/chatbot_model"
ENV LOCAL_NLP_MODEL_PATH="/app/app/ai_model/fintunning_nlp"

EXPOSE 8000

CMD ["uvicorn", "app.app:app", "--host", "0.0.0.0", "--port", "8000"]
