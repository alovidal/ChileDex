FROM python:3.11-slim

WORKDIR /app

# Dependencias del sistema para open-clip
RUN apt-get update && apt-get install -y --no-install-recommends \
    git && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# HF Spaces espera el puerto 7860
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8080"]