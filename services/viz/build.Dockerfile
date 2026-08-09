FROM node:20-alpine

# Install FFmpeg, git, and utilities
RUN apk add --no-cache git ffmpeg bash curl

ARG REPO_URL=https://git.orfel.de/Jannik/Viz.git
ARG BRANCH=main
ARG CACHE_BUST=2026-08-09T12:30:00Z

WORKDIR /app

RUN echo "Busting cache: $CACHE_BUST"
RUN git clone --depth 1 --branch ${BRANCH} ${REPO_URL} .
RUN npm ci --omit=dev

# Ensure directories and permissions
RUN mkdir -p /data/temp /data/uploads && chown -R node:node /app /data

USER node

EXPOSE 3000

CMD ["node", "server.mjs"]
