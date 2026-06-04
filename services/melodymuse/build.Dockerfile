# Stage 1: Build the Vite/React app
FROM node:20-alpine AS builder

RUN apk add --no-cache git

ARG REPO_URL=https://git.orfel.de/Jannik/MelodyMuse.git
ARG BRANCH=main

WORKDIR /build
# Cache bust to ensure the latest commit (with new hooks) is pulled
ARG CACHE_BUST=2026-06-04T12:57:00Z
RUN echo "Busting cache: $CACHE_BUST"
RUN git clone --depth 1 --branch ${BRANCH} ${REPO_URL} .
RUN npm ci
RUN npm run build

# Stage 2: Serve with Node
FROM node:20-alpine

WORKDIR /app
COPY --from=builder /build/package*.json ./
RUN npm ci --omit=dev

COPY --from=builder /build/dist ./dist
COPY --from=builder /build/server ./server
COPY --from=builder /build/server.mjs ./

EXPOSE 3000
CMD ["node", "server.mjs"]
