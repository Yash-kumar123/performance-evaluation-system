# Production Dockerfile for Performance Evaluation System Backend
FROM node:20-alpine AS runner

WORKDIR /app/backend

# Install Backend Production Dependencies
COPY backend/package*.json ./
RUN npm ci --only=production

# Copy Backend Source Code
COPY backend/ ./

EXPOSE 5000

ENV NODE_ENV=production
ENV PORT=5000

# Initialize Database Schema/Seed then Start Production Server
CMD ["sh", "-c", "node src/seed/seed.js || true; node server.js"]

