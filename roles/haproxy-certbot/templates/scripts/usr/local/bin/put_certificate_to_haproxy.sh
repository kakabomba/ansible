#!/usr/bin/env bash

cd /usr/local/bin


source /usr/local/bin/o-lib.sh

USAGE=$(basename $0)" main.domain.com"

hd=/etc/haproxy
ldl=/etc/letsencrypt/live

if [[ "$1" == '-h' || "$1" == '' ]]; then
  echo $USAGE
  exit
fi

cat $ldl/$1/fullchain.pem $ldl/$1/privkey.pem > $hd/certs/$1.pem

echo "$hd/default.pem" > $hd/list.txt

for f in $hd/certs/*.pem; do
  echo $f
  echo "$f" >> $hd/list.txt
done

service haproxy restart
