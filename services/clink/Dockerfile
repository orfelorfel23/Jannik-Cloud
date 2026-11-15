FROM alpine:latest AS builder

RUN apk add --no-cache build-base git

RUN git clone https://git.crueter.xyz/crueter/clink.git /src/clink
WORKDIR /src/clink
# Fix upstream heap buffer overflow in main.c (strcat onto exact-sized strdup buffer)
RUN sed -i 's|char \*links_dir = strcat(strdup(data_dir), "/links");|char *links_dir = malloc(strlen(data_dir) + 7); sprintf(links_dir, "%s/links", data_dir);|' main.c \
    && sed -i 's|char \*del_dir = strcat(strdup(data_dir), "/del");|char *del_dir = malloc(strlen(data_dir) + 5); sprintf(del_dir, "%s/del", data_dir);|' main.c \
    && make

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
