FROM python:3.12-alpine

ENV OJ_ENV production
WORKDIR /app

COPY requirements.txt /app/
# psycopg2: libpg-dev
# pillow: libjpeg-turbo-dev zlib-dev freetype-dev
RUN --mount=type=cache,target=/etc/apk/cache,id=apk-cahce-$TARGETARCH$TARGETVARIANT-final \
    --mount=type=cache,target=/root/.cache/pip,id=pip-cahce-$TARGETARCH$TARGETVARIANT-final \
    <<EOS
set -ex
apk add gcc libc-dev python3-dev libpq libpq-dev libjpeg-turbo libjpeg-turbo-dev zlib zlib-dev freetype freetype-dev supervisor
pip install -r /app/requirements.txt
apk del gcc libc-dev python3-dev libpq-dev libjpeg-turbo-dev zlib-dev freetype-dev
EOS

COPY ./ /app/
RUN chmod -R u=rwX,go=rX ./ && chmod +x /app/container/entrypoint.sh

HEALTHCHECK --interval=5s CMD [ "/usr/local/bin/python3", "/app/container/health_check.py" ]
EXPOSE 8080
ENTRYPOINT [ "/app/container/entrypoint.sh" ]
