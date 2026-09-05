# QMD-Container (lokale Hybridsuche fuer Mind-o-Mat)
# Multi-Stage-Build: install QMD + seine GGUF-Modelle (~2 GB)

FROM node:22-alpine AS build
WORKDIR /build

RUN apk add --no-cache git python3 make g++
RUN git clone --depth 1 https://github.com/tobilu/qmd.git /build/qmd
WORKDIR /build/qmd
RUN npm ci || npm install
RUN npm run build 2>/dev/null || true

FROM node:22-alpine
WORKDIR /app

# QMD installieren
RUN apk add --no-cache git bash
RUN npm install -g @tobilu/qmd

# Model-Cache vorab herunterladen (spart 2 GB beim ersten Start)
RUN qmd pull --progress || true

ENV NODE_ENV=production
ENV QMD_CACHE_DIR=/data
EXPOSE 8181

# QMD-Server (MCP-Endpoint) starten
CMD ["sh", "-c", "qmd mcp --http --daemon --host 0.0.0.0 --port 8181"]
