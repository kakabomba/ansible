#!/bin/bash

source /usr/local/bin/o-lib.sh

USAGE=$(basename $0)" email main.domain.com another.com www.yetanother.com..."

em=$1
shift

alld=""

for dom in "$@"; do
  if ! is_fqdn "$dom"; then
    _e "Wrong domain name $dom. $USAGE"
  fi
  alld="$alld -d $dom"
done

if [[ "$alld" == "" ]]; then
  _e "No domain specified. $USAGE"
fi

_n "Invoking: certbot certonly --allow-subset-of-names --noninteractive --agree-tos --email $em --webroot --webroot-path /var/www/html$alld 2>&1)"

ret=$(certbot certonly --allow-subset-of-names --noninteractive --agree-tos --email $em --webroot --webroot-path /var/www/html$alld 2>&1)

if [[ "$?" != "1" ]]; then
  _e "certbot returned: $ret"
fi

_n "certbot returned: $ret"
