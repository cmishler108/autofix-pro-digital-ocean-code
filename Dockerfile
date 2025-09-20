# Multi-stage build for Next.js frontend
FROM node:18-alpine AS frontend-builder

WORKDIR /app/frontend
COPY fr/package*.json ./
RUN npm ci

COPY fr/ ./
RUN npm run build

# Production frontend image
FROM node:18-alpine AS frontend-production
WORKDIR /app
COPY --from=frontend-builder /app/frontend/.next ./.next
COPY --from=frontend-builder /app/frontend/public ./public
COPY --from=frontend-builder /app/frontend/package*.json ./
COPY --from=frontend-builder /app/frontend/next.config.mjs ./

RUN npm ci --only=production

EXPOSE 3000
CMD ["npm", "start"]