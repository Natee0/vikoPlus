# syntax=docker/dockerfile:1

# 1. Shared dependency stage. Cached until package manifests change.
FROM node:24-alpine AS deps
WORKDIR /app
ENV NPM_CONFIG_AUDIT=false
ENV NPM_CONFIG_FUND=false

COPY package.json package-lock.json .npmrc ./
COPY apps/api/package.json ./apps/api/package.json
RUN --mount=type=cache,target=/root/.npm npm ci

# 2. Build stage - compile API only.
FROM deps AS build
COPY apps/api ./apps/api
WORKDIR /app/apps/api

# Generate Prisma Client
RUN npx prisma generate

# Build NestJS
RUN npm run build

# 3. Production dependency stage. Avoid npm prune after source changes.
FROM node:24-alpine AS prod-deps
WORKDIR /app
ENV NPM_CONFIG_AUDIT=false
ENV NPM_CONFIG_FUND=false

# Copy manifests from the completed build stage so Docker does not run the
# full dev install and production install in parallel on small VPS instances.
COPY --from=build /app/package.json /app/package-lock.json /app/.npmrc ./
COPY --from=build /app/apps/api/package.json ./apps/api/package.json
RUN --mount=type=cache,target=/root/.npm npm ci --omit=dev

# 4. Production runtime stage.
FROM node:24-alpine AS runtime
WORKDIR /app
ENV NODE_ENV=production

RUN apk add --no-cache openssl

COPY --from=prod-deps /app/node_modules ./node_modules
COPY --from=build /app/node_modules/.prisma ./node_modules/.prisma
COPY --from=build /app/node_modules/@prisma/client ./node_modules/@prisma/client
COPY --from=build /app/apps/api/dist ./apps/api/dist
COPY --from=build /app/apps/api/prisma ./apps/api/prisma
COPY package.json package-lock.json ./
COPY apps/api/package.json ./apps/api/package.json

USER node
WORKDIR /app/apps/api

EXPOSE 3000

# Start NestJS production build
CMD ["node", "dist/src/main.js"]
