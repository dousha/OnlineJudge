FROM python:3.8-alpine3.14

ENV OJ_ENV production

WORKDIR /app

HEALTHCHECK --interval=5s --retries=3 CMD python3 /app/deploy/health_check.py

RUN sed -i 's/https/http/' /etc/apk/repositories

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories

RUN apk add --update --no-cache build-base nginx openssl curl unzip supervisor jpeg-dev zlib-dev postgresql-dev freetype-dev && \
    pip config set global.index-url https://mirrors.sustech.edu.cn/pypi/simple

ADD deploy /app/deploy

RUN pip install --no-cache-dir -r /app/deploy/requirements.txt && \
    apk del build-base --purge

ADD . /app

ENTRYPOINT /app/deploy/entrypoint.sh
