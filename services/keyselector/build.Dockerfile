FROM node:20-alpine

RUN apk add --no-cache git

ARG REPO_URL=https://git.orfel.de/Jannik/KeySelector.git
ARG BRANCH=main
ARG CACHE_BUST=2026-08-26T01:05:00Z

WORKDIR /app
RUN echo "Busting cache: $CACHE_BUST"
RUN git clone --depth 1 --branch ${BRANCH} ${REPO_URL} .

WORKDIR /app/server
RUN npm ci --omit=dev

WORKDIR /app

RUN chown -R node:node /app
USER node

EXPOSE 3000
CMD ["node", "server/index.js"]
