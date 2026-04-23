FROM alpine:3.20

RUN apk add --no-cache \
    bash \
    rclone \
    postgresql17-client \
    curl \
    tzdata \
    gzip

COPY backup.sh /app/backup.sh
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/backup.sh /app/entrypoint.sh

WORKDIR /app
ENTRYPOINT ["/app/entrypoint.sh"]
