# syntax=docker/dockerfile:1

FROM node:22-bookworm-slim AS base

WORKDIR /opt/app

RUN apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates \
  && rm -rf /var/lib/apt/lists/*

COPY package*.json ./

FROM base AS deps

RUN npm ci

FROM deps AS build

ENV APP_KEYS=build-key-1,build-key-2
ENV API_TOKEN_SALT=build-token-salt
ENV ADMIN_JWT_SECRET=build-admin-jwt-secret
ENV TRANSFER_TOKEN_SALT=build-transfer-token-salt
ENV JWT_SECRET=build-jwt-secret
ENV ENCRYPTION_KEY=build-encryption-key

COPY . .
RUN npm run build

FROM node:22-bookworm-slim AS production

WORKDIR /opt/app

ENV NODE_ENV=production
ENV PATH=/opt/app/node_modules/.bin:$PATH

RUN apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates dumb-init \
  && rm -rf /var/lib/apt/lists/*

COPY --from=build /opt/app ./

RUN npm prune --omit=dev \
  && npm cache clean --force \
  && chown -R node:node /opt/app

USER node

EXPOSE 1337

CMD ["dumb-init", "npm", "run", "start"]
