# 1. Base stage - Install dependencies
FROM node:22-alpine AS dependencies
WORKDIR /app
COPY package*.json ./

RUN npm install

# 2. Build stage - Generate Prisma client & build NestJS JS code
FROM node:22-alpine AS build
WORKDIR /app
COPY package*.json ./
COPY --from=dependencies /app/node_modules ./node_modules
COPY . .

# Generate Prisma Client
RUN npx prisma generate

# Build NestJS
RUN npm run build

RUN npm prune --production

# 3. Production Runtime stage
FROM node:22-alpine AS runtime
WORKDIR /app
ENV NODE_ENV=production

COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY --from=build /app/prisma ./prisma
COPY package*.json ./

EXPOSE 3000

# Start NestJS production build
CMD ["node", "dist/src/main.js"]
