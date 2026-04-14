# Stage 1: Build the Vite/React app
FROM node:20-alpine AS builder

RUN apk add --no-cache git

ARG REPO_URL=https://github.com/H4f3rk3ks/spotify-plailist.git
ARG BRANCH=main

WORKDIR /build
RUN git clone --depth 1 --branch ${BRANCH} ${REPO_URL} .
RUN npm install
RUN npm run build

# Stage 2: Serve with Nginx
FROM nginx:alpine

COPY --from=builder /build/dist /usr/share/nginx/html

# Custom nginx config for SPA routing
RUN cat > /etc/nginx/conf.d/default.conf <<'EOF'
server {
    listen 80;
    server_name _;
    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
