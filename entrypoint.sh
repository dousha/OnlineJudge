#!/bin/sh

APP=/app
DATA=/data

mkdir -p $DATA/log $DATA/config $DATA/ssl $DATA/test_case $DATA/public/upload $DATA/public/avatar $DATA/public/website

if [ ! -f "$DATA/config/secret.key" ]; then
    echo $(cat /dev/urandom | head -1 | md5sum | head -c 32) > "$DATA/config/secret.key"
fi

if [ ! -f "$DATA/public/avatar/default.png" ]; then
    cp data/public/avatar/default.png $DATA/public/avatar
fi

if [ ! -f "$DATA/public/website/favicon.ico" ]; then
    cp data/public/website/favicon.ico $DATA/public/website
fi

SSL="$DATA/ssl"
if [ ! -f "$SSL/server.key" ]; then
    openssl req -x509 -newkey rsa:2048 -keyout "$SSL/server.key" -out "$SSL/server.crt" -days 1000 \
        -subj "/C=CN/ST=Beijing/L=Beijing/O=Beijing OnlineJudge Technology Co., Ltd./OU=Service Infrastructure Department/CN=`hostname`" -nodes
fi

cd $APP/deploy/nginx
ln -sf locations.conf https_locations.conf
if [ -z "$FORCE_HTTPS" ]; then
    ln -sf locations.conf http_locations.conf
else
    ln -sf https_redirect.conf http_locations.conf
fi

if [ ! -z "$LOWER_IP_HEADER" ]; then
    sed -i "s/__IP_HEADER__/\$http_$LOWER_IP_HEADER/g" api_proxy.conf;
else
    sed -i "s/__IP_HEADER__/\$remote_addr/g" api_proxy.conf;
fi

if [ -z "$MAX_WORKER_NUM" ]; then
    export CPU_CORE_NUM=$(grep -c ^processor /proc/cpuinfo)
    if [[ $CPU_CORE_NUM -lt 2 ]]; then
        export MAX_WORKER_NUM=2
    else
        export MAX_WORKER_NUM=$(($CPU_CORE_NUM))
    fi
fi

echo "Applying CDN configurations..."

cd $APP/dist
if [ ! -z "$STATIC_CDN_HOST" ]; then
    echo "Using CDN host ${STATIC_CDN_HOST}"
    find . -name "*.css" -type f -exec sed -i "s/__STATIC_CDN_HOST__/\/$STATIC_CDN_HOST/g" {} \;
    find . -name "*.js" -type f -exec sed -i "s/__STATIC_CDN_HOST__/\/$STATIC_CDN_HOST/g" {} \;
    find . -name "*.html" -type f -exec sed -i "s/__STATIC_CDN_HOST__/\/$STATIC_CDN_HOST/g" {} \;
else
    echo "Not using CDN host"
    find . -name "*.css" -type f -exec sed -i "s/__STATIC_CDN_HOST__\///g" {} \;
    find . -name "*.js" -type f -exec sed -i "s/__STATIC_CDN_HOST__\///g" {} \;
    find . -name "*.html" -type f -exec sed -i "s/__STATIC_CDN_HOST__\///g" {} \;
fi

echo "Server initialization"

cd $APP

n=0
while [ $n -lt 5 ]
do
    python manage.py makemigrations &&
    python manage.py migrate --no-input &&
    python manage.py inituser --username=root --password=rootroot --action=create_super_admin &&
    echo "from options.options import SysOptions; SysOptions.judge_server_token='$JUDGE_SERVER_TOKEN'" | python manage.py shell &&
    echo "from conf.models import JudgeServer; JudgeServer.objects.update(task_number=0)" | python manage.py shell &&
    break
    n=$(($n+1))
    echo "Failed to migrate, going to retry..."
    sleep 8
done

echo "Adding app user"

addgroup -g 12003 spj
adduser -u 12000 -S -G spj server

echo "starting server..."

chown -R server:spj $DATA $APP/dist
find $DATA/test_case -type d -exec chmod 710 {} \;
find $DATA/test_case -type f -exec chmod 640 {} \;
exec supervisord -c /app/deploy/supervisord.conf

echo "server started"