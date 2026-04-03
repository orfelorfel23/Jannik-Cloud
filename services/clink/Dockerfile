FROM alpine:latest AS builder

RUN apk add --no-cache build-base git

RUN git clone https://git.crueter.xyz/crueter/clink.git /src/clink
WORKDIR /src/clink
RUN make

FROM alpine:latest

RUN apk add --no-cache libc6-compat

COPY --from=builder /src/clink/clink /usr/local/bin/clink

RUN mkdir -p /srv/clink
VOLUME /srv/clink

EXPOSE 8080

CMD ["clink"]
