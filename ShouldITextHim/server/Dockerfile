# Builds the application API only — NOT the inference server. Run this
# alongside a separately-run llama.cpp server or Ollama container (see
# docker-compose.example.yml). Do not publish the inference server's own
# port to the host or the public internet; only this API container
# should be reachable from outside the private network it runs on.

FROM node:20-slim AS build
WORKDIR /app
COPY package.json tsconfig.json tsconfig.scripts.json ./
COPY src ./src
COPY scripts ./scripts
RUN npm install && npm run build

FROM node:20-slim
WORKDIR /app
ENV NODE_ENV=production
COPY package.json ./
RUN npm install --omit=dev
COPY --from=build /app/dist ./dist
EXPOSE 3000
CMD ["node", "dist/server.js"]
