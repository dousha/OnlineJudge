FROM python:3.12-alpine AS builder
ARG TARGETARCH
ARG TARGETVARIANT
ENV POETRY_VIRTUALENVS_IN_PROJECT=true
WORKDIR /app

COPY pyproject.toml poetry.lock /app/
# psycopg2: libpg-dev
# pillow: libjpeg-turbo-dev zlib-dev freetype-dev
RUN --mount=type=cache,target=/etc/apk/cache,id=apk-cahce-$TARGETARCH$TARGETVARIANT-builder \
    --mount=type=cache,target=/root/.cache/pypoetry,id=poetry-cahce-$TARGETARCH$TARGETVARIANT-builder \
    <<EOS
set -ex
apk add poetry gcc libc-dev python3-dev libpq-dev libjpeg-turbo-dev zlib-dev freetype-dev
poetry env use /usr/local/bin/python3
poetry install --no-interaction --without dev --no-root
EOS

FROM python:3.12-alpine
ARG TARGETARCH
ARG TARGETVARIANT
ENV OJ_ENV production
ENV PATH="/app/.venv/bin:$PATH"
WORKDIR /app

RUN --mount=type=cache,target=/etc/apk/cache,id=apk-cahce-$TARGETARCH$TARGETVARIANT-final \
    apk add libpq libjpeg-turbo lzlib freetype

COPY ./ /app/
RUN chmod -R u=rwX,go=rX ./ && chmod +x /app/entrypoint.sh
COPY --from=builder --link /app/.venv/ /app/.venv/

EXPOSE 8080
CMD [ "/app/entrypoint.sh" ]
