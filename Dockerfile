# syntax=docker/dockerfile:1

FROM node:22-alpine AS build
WORKDIR /app

COPY app/package.json app/package-lock.json ./
RUN npm ci

COPY app/tsconfig.json app/tsconfig.build.json ./
COPY app/src ./src
RUN npm run build

FROM node:22-alpine AS runtime
WORKDIR /app

RUN addgroup -S shipyard && adduser -S shipyard -G shipyard

COPY --from=build --chown=shipyard:shipyard /app/package.json ./
COPY --from=build --chown=shipyard:shipyard /app/dist ./dist

USER shipyard
ENV NODE_ENV=production
ENV PORT=8080
EXPOSE 8080

CMD ["node", "dist/index.js"]
