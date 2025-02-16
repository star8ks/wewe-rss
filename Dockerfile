FROM node:20.16.0-alpine AS base
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

# Install specific version of pnpm
RUN npm install -g pnpm@8.15.4

FROM base AS build
COPY . /usr/src/app
WORKDIR /usr/src/app

# Use cache for both install and build
RUN --mount=type=cache,id=pnpm,target=/pnpm/store \
    pnpm install --force && \
    pnpm run -r build

RUN pnpm deploy --filter=server --prod /app

RUN cd /app && \
    rm -rf ./prisma && \
    mv prisma-sqlite prisma && \
    pnpm exec prisma generate

FROM base AS app
# No need to reinstall pnpm as it's already in base
COPY --from=build /app /app

WORKDIR /app

EXPOSE 4000

ENV NODE_ENV=production
ENV HOST="0.0.0.0"
# ENV SERVER_ORIGIN_URL=""
# ENV AUTH_CODE=""
ENV MAX_REQUEST_PER_MINUTE=60
ENV DATABASE_URL="file:../data/wewe-rss.db"
ENV DATABASE_TYPE="sqlite"

RUN chmod +x ./docker-bootstrap.sh

CMD ["./docker-bootstrap.sh"]