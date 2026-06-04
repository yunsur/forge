FROM node:24.16.0-slim

RUN npm config set registry http://172.21.3.9:8081/repository/npm_group
RUN npm install -g pnpm@latest

WORKDIR /app

COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

COPY . .

EXPOSE 8080

CMD ["pnpm", "dev", "--host", "0.0.0.0", "--port", "8080"]
