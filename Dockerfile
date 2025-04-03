# Dockerfile (React + Flask build)
# ========== Frontend (React) Build ==========
FROM node:20 as frontend
WORKDIR /app
COPY frontend ./frontend
WORKDIR /app/frontend
RUN npm install && npm run build

# ========== Backend (Flask) ==========
FROM python:3.11-slim as backend
WORKDIR /app

# Install Python dependencies
COPY backend/requirements.txt .
RUN pip install -r requirements.txt

# Install system tools (speedtest, ping, Docker CLI)
RUN apt update && apt install -y speedtest-cli iputils-ping docker-cli nginx

# Copy backend and frontend
COPY backend /app/backend
COPY --from=frontend /app/frontend/dist /app/frontend
COPY nginx.conf /etc/nginx/nginx.conf

# Expose and run
EXPOSE 80
CMD service nginx start && python3 /app/backend/app.py
