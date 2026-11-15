FROM alpine:latest AS builder

RUN apk add --no-cache build-base git

RUN git clone https://git.crueter.xyz/crueter/clink.git /src/clink
WORKDIR /src/clink
RUN make

FROM alpine:latest

RUN apk add --no-cache libc6-compat \
    && addgroup -g 10001 -S appgroup \
    && adduser -u 10001 -S appuser -G appgroup

COPY --from=builder /src/clink/clink /usr/local/bin/clink

RUN mkdir -p /srv/clink && chown -R appuser:appgroup /srv/clink
VOLUME /srv/clink

USER appuser

EXPOSE 8080

CMD ["clink"]
