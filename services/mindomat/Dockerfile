# Mind-o-Mat: Webapp + QMD in einem Image
# Multi-Stage-Build: install dependencies, build webapp, prepare qmd

# === Stage 1: Webapp-Build ===
FROM node:22-alpine AS webapp
WORKDIR /build

# Tools fuer git-clone
RUN apk add --no-cache git openssh-client

ENV NODE_OPTIONS="--max-old-space-size=2048"

# Tool-Repo (fuer evtl. CLI-Aufrufe)
ARG TOOL_REPO=https://git.orfel.de/Jannik/Mind-o-Mat.git
RUN git clone --depth 1 ${TOOL_REPO} /build/mindomat-tool

# Webapp-Repo
ARG WEBAPP_REPO=https://git.orfel.de/Jannik/Mind-o-Mat-Webapp.git
RUN git clone --depth 1 ${WEBAPP_REPO} /build/app

WORKDIR /build/app
RUN npm ci --no-audit --no-fund || npm install --no-audit --no-fund
RUN npm run build
# Output: /build/app/dist

# === Stage 2: QMD-Vorbereitung ===
FROM node:22-alpine AS qmd-prep
RUN apk add --no-cache git bash python3 make g++
RUN npm install -g @tobilu/qmd
# Modelle werden zur Laufzeit geladen (nicht im Image), spart ~2 GB Image-Groesse
# Falls die Modelle im Image sein sollen: qmd pull --progress hier ausfuehren

# === Final: Kombiniertes Image ===
FROM node:22-alpine
WORKDIR /app

# System-Tools
RUN apk add --no-cache git bash curl tini

# QMD (vom prep-Stage kopiert, mit PATH)
COPY --from=qmd-prep /usr/local/lib/node_modules/@tobilu/qmd /opt/mindomat/qmd
ENV PATH="/opt/mindomat/qmd/bin:${PATH}"

# Webapp-Build
COPY --from=webapp /build/app/dist /app/webapp/dist
COPY --from=webapp /build/app/package.json /app/webapp/package.json
COPY --from=webapp /build/app/server.mjs /app/webapp/server.mjs

# Tool-CLI (optional, fuer Ingest-Operationen per SSH)
COPY --from=webapp /build/mindomat-tool /opt/mindomat/tool

# Persistente Volumes
ENV QMD_CACHE_DIR=/data
ENV MINDOMAT_VAULT_PATH=/vault
ENV NODE_ENV=production
ENV PORT=5173

EXPOSE 5173 8181

# Production-Server starten
# 1. QMD (MCP/HTTP-Server fuer die Suche)
# 2. Webapp-Server (Express + API-Proxy)
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/sbin/tini", "--", "/entrypoint.sh"]

# Volumes:
# - /mnt/Jannik-Cloud-Volume-01/mindomat-vault:/vault
# - /mnt/Jannik-Cloud-Volume-01/mindomat-qmd:/data
