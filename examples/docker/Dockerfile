# Dockerfile example - Multi-stage build for a Python/Node.js app
# Stage 1: Build frontend
FROM node:20-alpine AS frontend-builder

WORKDIR /app/frontend

# Copy package files
COPY frontend/package*.json ./
RUN npm ci --only=production

# Copy source and build
COPY frontend/ .
RUN npm run build

# Stage 2: Build backend
FROM python:3.12-slim AS backend-builder

WORKDIR /app/backend

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY backend/ .

# Stage 3: Runtime
FROM python:3.12-slim AS runtime

LABEL maintainer="DevMedia Team <devmedia@example.com>"
LABEL description="DevMedia Example Application"
LABEL version="1.0.0"

# Create non-root user
RUN groupadd -r devmedia && useradd -r -g devmedia -d /app -s /bin/false devmedia

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    libpq5 \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy artifacts from builder stages
COPY --from=backend-builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=backend-builder /app/backend /app/backend
COPY --from=frontend-builder /app/frontend/dist /app/frontend/dist

# Copy configuration
COPY docker-entrypoint.sh /usr/local/bin/
COPY --chown=devmedia:devmedia .env.production /app/.env

# Create necessary directories
RUN mkdir -p /app/data /app/logs /app/uploads && \
    chown -R devmedia:devmedia /app && \
    chmod +x /usr/local/bin/docker-entrypoint.sh

# Switch to non-root user
USER devmedia

# Expose ports
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PATH="/app/backend:$PATH"

# Entry point
ENTRYPOINT ["docker-entrypoint.sh"]

# Default command
CMD ["gunicorn", "main:app", "--workers", "4", "--worker-class", "uvicorn.workers.UvicornWorker", "--bind", "0.0.0.0:8000"]
