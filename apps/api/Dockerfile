# 1. Base stage kwa ajili ya dependencies zote (dev + prod)
FROM node:22-alpine AS dependencies
WORKDIR /app
COPY package*.json ./
RUN npm ci

# 2. Build stage - Generate Prisma client & build JS code
FROM node:22-alpine AS build
WORKDIR /app
COPY package*.json ./
COPY --from=dependencies /app/node_modules ./node_modules
COPY . .
RUN npm run prisma:generate
RUN npm run build
# Prune devDependencies ili kubaki na production modules pekee
RUN npm prune --production

# 3. Final Runtime stage - Lean & clean production image
FROM node:22-alpine AS runtime
WORKDIR /app
ENV NODE_ENV=production

# Nakili production node_modules na built dist pekee
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY --from=build /app/prisma ./prisma
COPY package*.json ./

EXPOSE 3000

CMD ["node", "dist/main.js"]
