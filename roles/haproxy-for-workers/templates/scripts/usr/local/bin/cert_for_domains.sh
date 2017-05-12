#!/bin/bash

source /usr/local/bin/o-lib.sh

USAGE=$(basename $0)" main.domain.com another.com www.yetanother.com..."

aliasesd=""

for dom in "$@"; do
  if ! is_fqdn $dom; then
    _e "Wrong domain name $dom. $USAGE"
  fi
  aliasesd="$aliasesd $dom"
done

if [[ "$aliasesd" == "" ]]; then
  _e "No domain specified. $USAGE"
fi

required=$(echo "$aliasesd" | xargs -n1 | sort | xargs)
domainsorted=$(certbot certificates | while read line; do 
    if [[ $(echo $line | grep '^\s*Domains:\s*') == "" ]]; then
      echo $line
    else
      echo $line | sed -e 's/^\s*Domains:\s*//' | xargs -n1 | sort -u | xargs | sed 's/.*/Domains: \0/'
    fi
  done
)

exists=$(echo "$domainsorted" | grep "^Domains: $required\$")
if [[ $exists == "Domains: $required" ]]; then
  echo "$domainsorted" | grep "^Domains: $required\$" -B1 -A3
fi

