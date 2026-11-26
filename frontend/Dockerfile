# syntax=docker/dockerfile:1
# Multi-stage build for the Next.js site:
#   deps    → install node_modules (cached until package-lock.json changes)
#   build   → next build (produces .next/standalone)
#   runtime → only server.js + the files it needs, on a small Node image
#
# Build:  docker build -t portfolio-web ./frontend
# Run:    docker compose up -d frontend   (see docker-compose.yml)

ARG NODE_VERSION=24-alpine

############################ Stage 1: dependencies ############################
FROM node:${NODE_VERSION} AS deps
WORKDIR /app
COPY package.json package-lock.json ./
# npm ci = exact versions from the lockfile; cache mount makes rebuilds fast
RUN --mount=type=cache,target=/root/.npm npm ci

############################ Stage 2: build ############################
FROM node:${NODE_VERSION} AS build
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# NEXT_PUBLIC_* values are baked into the JavaScript at BUILD time (the browser reads
# them), so the API address must be passed as a build argument, not a runtime env var.
# Locally the browser calls the backend at localhost:8080; on AWS this becomes the API's
# public URL, e.g. --build-arg NEXT_PUBLIC_API_URL=https://api.vishal.dev
ARG NEXT_PUBLIC_API_URL=http://localhost:8080
ENV NEXT_PUBLIC_API_URL=${NEXT_PUBLIC_API_URL}
ENV NEXT_TELEMETRY_DISABLED=1

RUN npm run build

############################ Stage 3: run ############################
FROM node:${NODE_VERSION} AS runtime
WORKDIR /app
ENV NODE_ENV=production \
    NEXT_TELEMETRY_DISABLED=1 \
    PORT=3000 \
    HOSTNAME=0.0.0.0

# The node image ships a non-root "node" user; run as that, not root
USER node

# standalone = server.js + traced node_modules. public/ and .next/static aren't included
# by default (Next.js expects a CDN for them), so copy them next to the server.
COPY --from=build --chown=node:node /app/.next/standalone ./
COPY --from=build --chown=node:node /app/.next/static ./.next/static
COPY --from=build --chown=node:node /app/public ./public

EXPOSE 3000

HEALTHCHECK --interval=10s --timeout=3s --start-period=20s --retries=5 \
  CMD wget -qO- http://127.0.0.1:3000/ > /dev/null || exit 1

CMD ["node", "server.js"]
