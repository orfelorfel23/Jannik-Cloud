FROM nginx:alpine

RUN apk add --no-cache git

ARG REPO_URL=https://git.orfel.de/Orfel-HermesAI-Bot/Herbstausfahrt.git
ARG BRANCH=main

WORKDIR /build
RUN git clone --depth 1 --branch ${BRANCH} ${REPO_URL} .
RUN cp -r . /usr/share/nginx/html
RUN rm -rf /usr/share/nginx/html/.git

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
