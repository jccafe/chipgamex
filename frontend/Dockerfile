# --- build stage ---
FROM node:20-alpine AS builder
WORKDIR /app

# 先複製 package 檔（利用 Docker layer cache）
COPY package*.json ./

# 有 lockfile 用 npm ci；沒有就 npm install
RUN if [ -f package-lock.json ]; then npm ci; else npm install; fi

# 複製原始碼並建置
COPY . .
RUN npm run build

# --- runtime stage ---
FROM nginx:1.27-alpine
RUN apk add --no-cache curl
WORKDIR /usr/share/nginx/html

# 清掉 nginx 預設頁
RUN rm -rf ./*

# 複製前端建置產物
COPY --from=builder /app/dist ./

# 自訂 nginx 設定（支援 SPA 路由 fallback）
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
# --- build stage ---
FROM node:20-alpine AS builder
WORKDIR /app

# 先複製 package 檔（利用 Docker layer cache）
COPY package*.json ./

# 有 lockfile 用 npm ci；沒有就 npm install
RUN if [ -f package-lock.json ]; then npm ci; else npm install; fi

# 複製原始碼並建置
COPY . .
RUN npm run build

# --- runtime stage ---
FROM nginx:1.27-alpine
RUN apk add --no-cache curl
WORKDIR /usr/share/nginx/html

# 清掉 nginx 預設頁
RUN rm -rf ./*

# 複製前端建置產物
COPY --from=builder /app/dist ./

# 自訂 nginx 設定（支援 SPA 路由 fallback）
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]

