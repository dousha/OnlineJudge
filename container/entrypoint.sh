#!/bin/sh
set -ex

APP=/app
DATA=/data

mkdir -p $DATA/log $DATA/config $DATA/test_case $DATA/public/upload $DATA/public/avatar $DATA/public/website

if [ ! -f "$DATA/config/secret.key" ]; then
    echo $(cat /dev/urandom | head -1 | md5sum | head -c 32) > "$DATA/config/secret.key"
fi

if [ ! -f "$DATA/public/avatar/default.png" ]; then
    cp data/public/avatar/default.png $DATA/public/avatar
fi

if [ ! -f "$DATA/public/website/favicon.ico" ]; then
    cp data/public/website/favicon.ico $DATA/public/website
fi

python manage.py migrate --no-input
python manage.py inituser --username=root --password=rootroot --action=create_super_admin
echo "from options.options import SysOptions; SysOptions.judge_server_token='$JUDGE_SERVER_TOKEN'" | python manage.py shell
echo "from conf.models import JudgeServer; JudgeServer.objects.update(task_number=0)" | python manage.py shell

addgroup -g 903 spj
adduser -u 900 -S -s /sbin/nologin -H -G spj server

chown -R server:spj $DATA
find $DATA/test_case -type d -exec chmod 710 {} \;
find $DATA/test_case -type f -exec chmod 640 {} \;

CPU_CORE_NUM="$(nproc)"
if [ "$CPU_CORE_NUM" -lt 2 ]; then
    export WORKER_NUM=2;
else
    export WORKER_NUM="$CPU_CORE_NUM";
fi

gunicorn oj.wsgi --user server --group spj --bind 0.0.0.0:8080 --workers $WORKER_NUM
