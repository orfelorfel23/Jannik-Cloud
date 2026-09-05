# Mind-o-Mat Webapp (Vite + React + Cytoscape + Tiptap)
# Multi-Stage-Build: deps install, build, slim runtime

FROM node:22-alpine AS build
WORKDIR /app

# Build-Tools brauchen mehr Memory in Alpine
ENV NODE_OPTIONS="--max-old-space-size=2048"

# Tool-Repo clonen (fuer das Tool-Package, das die Webapp mit-startet)
ARG TOOL_REPO=https://git.orfel.de/Jannik/Mind-o-Mat.git
RUN apk add --no-cache git openssh-client
RUN git clone --depth 1 ${TOOL_REPO} /tmp/mindomat-tool

# Webapp-Repo clonen
ARG WEBAPP_REPO=https://git.orfel.de/Jannik/Mind-o-Mat-Webapp.git
RUN git clone --depth 1 ${WEBAPP_REPO} /app

WORKDIR /app
RUN npm ci || npm install

# Vite-Build (statische Dateien in /app/dist)
RUN npm run build

# Server-Phase: statische Dateien ausliefern mit einem kleinen Node-Server
FROM node:22-alpine
WORKDIR /app

# Statische Webapp-Build
COPY --from=build /app/dist ./dist

# Kleiner HTTP-Server fuer statische Dateien + Reverse-Proxy zu Notes-API
RUN npm install --no-save express@^4.18.0 http-proxy-middleware@^2.0.0

# Server-Skript
COPY server.mjs ./

ENV NODE_ENV=production
ENV PORT=5173
EXPOSE 5173

CMD ["node", "server.mjs"]
