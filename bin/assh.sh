#!/bin/bash

cd $(dirname $(readlink $0))
cd ..

# ssh to ansible host

echo "connecting to " $2 at $1

varansible=$(ansible -i inventories/$1.py -m debug -a "var=hostvars['$2']" $2)

#echo $varansible

varjson=$(echo $varansible | tr '\n' ' ' | sed -e 's/\s\+//g' | sed -e 's/.*|SUCCESS=>//' )

#echo $varjson

host_port=$(echo $varjson | python3 -c "import sys, json; i=json.load(sys.stdin); l=lambda x: i[\"hostvars['$2']\"][x]; print(l('ansible_host'), l('ansible_port'))")

echo "ssh root@$(echo $host_port | cut -d ' ' -f1) -p$(echo $host_port | cut -d ' ' -f2) $3"

ssh root@$(echo $host_port | cut -d ' ' -f1) -p$(echo $host_port | cut -d ' ' -f2) $3

#echo $variables

