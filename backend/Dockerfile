# ── Stage 1: Build ──────────────────────────────────────────────────────
FROM node:20-alpine AS builder
WORKDIR /app

COPY package*.json ./
RUN npm ci --ignore-scripts

COPY tsconfig.json ./
COPY src ./src

# Generate Prisma client
COPY src/prisma/schema.prisma ./prisma/schema.prisma
RUN npx prisma generate

RUN npm run build

# ── Stage 2: Production ──────────────────────────────────────────────────
FROM node:20-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production

# Only production dependencies
COPY package*.json ./
RUN npm ci --omit=dev --ignore-scripts

# Copy built files and Prisma client
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules/.prisma ./node_modules/.prisma
COPY --from=builder /app/node_modules/@prisma ./node_modules/@prisma

# Prisma schema needed at runtime for migrations
COPY src/prisma/schema.prisma ./prisma/schema.prisma

# Cloud Run injects PORT env var (default 8080).
# Our app reads process.env.PORT so this works automatically.
EXPOSE 8080

CMD ["node", "dist/server.js"]
