#!/bin/bash

if [[ "$1" == "-h" ]]; then
    echo "Usage: "`basename "$0"`"
Resync haproxy
"
    exit
fi

haproxy_ip=10.10.9.$(ifconfig | grep 'addr:10\.10\.' | sed -e 's/.*addr:10\.10\.\([^.]*\).*/\1/')

ssh -i ~/.ssh/haproxy_worker_communication_id_rsa "$haproxy_ip"
