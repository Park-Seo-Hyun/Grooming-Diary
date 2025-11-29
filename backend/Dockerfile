FROM python:3.10-slim

ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

WORKDIR /app

RUN app-get update &&\
    app-get install -y build-essential gcc curl &&\
    rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

RUN pip install --no--cache-dir -r requirements.txt

COPY ./app /app/app

RUN mkdir -p /app/app/images && \
    mkdir -p /app/app/temp_data && \
    chmod -R 777 /app/app/images /app/app/temp_data

EXPOSE 8000

CMD ["uvicorn", "app.app:app", "--host", "0.0.0.0", "--port", "8000"]