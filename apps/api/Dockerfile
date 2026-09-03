# 1. Build stage - install from the monorepo lockfile and compile API only.
FROM node:24-alpine AS build
WORKDIR /app

COPY package.json package-lock.json .npmrc ./
COPY apps/api/package.json ./apps/api/package.json
RUN npm ci

COPY apps/api ./apps/api
WORKDIR /app/apps/api

# Generate Prisma Client
RUN npx prisma generate

# Build NestJS
RUN npm run build

WORKDIR /app
RUN npm prune --omit=dev

# 2. Production runtime stage.
FROM node:24-alpine AS runtime
WORKDIR /app
ENV NODE_ENV=production

RUN apk add --no-cache openssl

COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/apps/api/dist ./apps/api/dist
COPY --from=build /app/apps/api/prisma ./apps/api/prisma
COPY package.json package-lock.json ./
COPY apps/api/package.json ./apps/api/package.json

USER node
WORKDIR /app/apps/api

EXPOSE 3000

# Start NestJS production build
CMD ["node", "dist/src/main.js"]
