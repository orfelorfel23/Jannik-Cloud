FROM node:18-alpine AS builder
RUN apk add --no-cache libc6-compat openssl
WORKDIR /app

# Enable pnpm
RUN corepack enable pnpm

# Copy everything
COPY . .

# Install dependencies
RUN pnpm install

# Generate Prisma client
RUN cd apps/web && pnpm prisma:generate

# Build the application
RUN pnpm build

# Runner stage
FROM node:18-alpine AS runner
WORKDIR /app
RUN apk add --no-cache openssl
RUN corepack enable pnpm

ENV NODE_ENV production
ENV NEXT_TELEMETRY_DISABLED 1
ENV PORT 3000

# Copy the built app
COPY --from=builder /app /app

EXPOSE 3000

CMD ["pnpm", "--filter", "web", "start"]
