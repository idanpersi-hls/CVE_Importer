FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt /app
COPY src/ /app/src/
COPY .env /app/.env

RUN apt-get update && apt-get install -y \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir -r requirements.txt

CMD ["python", "-m", "src.main"]