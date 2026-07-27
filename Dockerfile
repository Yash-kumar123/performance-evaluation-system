# Multi-Stage Dockerfile for Performance Evaluation System
# Stage 1: Build Flutter Web Frontend Application
FROM ghcr.io/cirrusci/flutter:3.22.0 AS flutter-builder

WORKDIR /app/frontend
COPY frontend/pubspec.yaml frontend/pubspec.lock ./
RUN flutter pub get

COPY frontend/ .
RUN flutter build web --release

# Stage 2: Production Node.js Server & Web Host
FROM node:20-alpine AS runner

WORKDIR /app

# Install Backend Production Dependencies
COPY backend/package*.json ./backend/
WORKDIR /app/backend
RUN npm ci --only=production

# Copy Backend Source Code
COPY backend/ ./

# Copy Built Flutter Web Assets into Target Frontend Path
COPY --from=flutter-builder /app/frontend/build/web /app/frontend/build/web

EXPOSE 5000

ENV NODE_ENV=production
ENV PORT=5000

# Initialize Database Schema/Seed then Start Production Server
CMD ["sh", "-c", "node src/seed/seed.js || true; node server.js"]
