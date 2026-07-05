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

# Install dependencies
RUN pnpm install

# Generate Prisma client
RUN cd apps/web && pnpm prisma:generate

# Build the application
RUN pnpm build

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

CMD npx prisma db push --schema=./apps/web/prisma/schema.prisma --accept-data-loss && pnpm --filter web start
