#!/bin/bash

if [[ "$1" == "-h" ]] || [[ $# -ne 1 ]]; then
    echo "Usage: "`basename "$0"`" host.name 
remove files in /var/www/host.name (only when it look like project). Remove also Apache conf file /etc/apache2/sites-enabled/host.name.conf
"
    exit
fi


proj=$1

di="/var/www/$1"
if [[ -d $di && -d $di/web && -d $di/log && -d $di/config ]]; then
  echo removing "$di"
  rm -rf /var/www/$1/*
  rmdir /var/www/$1
  rm /etc/apache2/sites-enabled/$1.conf
else
  echo "Project $di don't look like web-project. directories $di,$di/web,$di/log,$di/config should exists"
fi

service apache2 restart

/usr/local/bin/ntaxa-apache-haproxy-sync.sh

#echo "Please wait a fem minutes until proxy server sync aliases.
#All aliases (ServerName and ServerAliases) from $di/config/aliases*.config goes to proxy server every few minutes"

