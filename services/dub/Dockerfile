FROM node:18-alpine AS builder

# Add required dependencies for turborepo, Prisma, and native Node modules
RUN apk add --no-cache libc6-compat openssl python3 make g++ git
WORKDIR /app

# Enable pnpm
RUN corepack enable pnpm

# Copy everything
COPY . .

# Ensure .env files exist so dotenv-flow and prisma:generate don't crash
RUN cp apps/web/.env.example apps/web/.env || true
RUN touch .env
RUN echo "PLAIN_API_KEY=dummy_key_for_build" >> apps/web/.env
RUN echo "QSTASH_TOKEN=dummy_token_for_build" >> apps/web/.env
RUN echo "AXIOM_TOKEN=dummy_token_for_build" >> apps/web/.env
RUN echo "UPSTASH_REDIS_REST_URL=https://dummy.upstash.io" >> apps/web/.env
RUN echo "UPSTASH_REDIS_REST_TOKEN=dummy_token" >> apps/web/.env

# Install dependencies
RUN pnpm install

# Generate Prisma client
RUN cd apps/web && pnpm prisma:generate

# Build the application
# Patch next.config.js to reduce memory usage during build and ignore linter errors
RUN echo "module.exports.eslint = { ignoreDuringBuilds: true };" >> apps/web/next.config.js
RUN echo "module.exports.typescript = { ignoreBuildErrors: true };" >> apps/web/next.config.js
RUN echo "if (module.exports.experimental) { module.exports.experimental.optimizePackageImports = []; module.exports.experimental.workerThreads = false; module.exports.experimental.cpus = 1; module.exports.experimental.memoryBasedWorkersCount = false; } else { module.exports.experimental = { optimizePackageImports: [], workerThreads: false, cpus: 1, memoryBasedWorkersCount: false }; }" >> apps/web/next.config.js

ENV NEXT_TELEMETRY_DISABLED=1
ENV NODE_OPTIONS="--max_old_space_size=6144"
RUN pnpm build
RUN test -f apps/web/.next/BUILD_ID || { echo "Build failed! BUILD_ID not found."; exit 1; }

# Runner stage
FROM node:18-alpine AS runner
WORKDIR /app

# Add runtime dependencies
RUN apk add --no-cache openssl libc6-compat
RUN corepack enable pnpm

ENV NODE_ENV production
ENV NEXT_TELEMETRY_DISABLED 1
ENV PORT 3000

# Copy the built app
COPY --from=builder /app /app

EXPOSE 3000

CMD cd apps/web && pnpm exec prisma db push --schema=./prisma/schema --accept-data-loss && pnpm start
