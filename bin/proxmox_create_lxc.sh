#!/usr/bin/env bash

usr=$(cat ../inventories/profi.json | jq -r .username)
pass=$(cat ../inventories/profi.json | jq -r .password)
url=$(cat ../inventories/profi.json | jq -r .url)

net=$1
id=$2
hostname=$3

up="username=$usr&password=$pass"
cookie=$(curl --silent --insecure --data "$up"  "$url"api2/json/access/ticket | jq --raw-output '.data.ticket' | sed 's/^/PVEAuthCookie=/')
csrftoken=$(curl --silent --insecure --data "$up" "$url"api2/json/access/ticket | jq --raw-output '.data.CSRFPreventionToken' | sed 's/^/CSRFPreventionToken:/')


curl --silent --insecure  --cookie "$cookie" --header "$csrftoken" -X POST\
 --data-urlencode ostemplate="local:vztmpl/debian-8.0-standard_8.6-1_amd64.tar.gz" \
 --data "vmid=$net$id"\
 --data storage=images\
 --data cores=1\
 --data onboot=1\
 --data "hostname=$hostname"\
 --data rootfs=3\
 --data-urlencode ssh-public-keys="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDSNm9mli6Xom6J70bMCr5jgnvuZ0JzT6boNFd3bjOL48tnVLHcHZ36BpJLWFjn7dyxlewXzvL6Oe3jqUBMo3g5G2voRN8aYdhYqIAKPJBFsYmZs6t3QYGhp/iegny1wlZRSGbxkjrbIvFlQMZQnfuLEY7oKGP9iFvqEc16sqYLH+wBSNfGt/tYIzLpSFtIso/OeS+THDqjc6AgaLBpLxEYGkhjoiqTtwkHZz6KNgN0N/kjGjbIzjsXHZIphV0OC3WAJsYKYuemKYi1p9wAHZH7hKEJge2zsV3NZHndDISJMwAc/dpq5RZ4Je5QbjILUK1ooIpXPwoEppnXEmTO3RF8cQ+eRD1Oq3bckJw3qLhYJH2WrQ5ErFciKUnOWBlnJ3Vmd8kKMzumjFdYJROaZNrECo8o/SQeeiNiG0HHMsuEmh1jPd+lUJDOYNKoceSDe/3VI73igw5DeQb6rDorv/Iqozmb8GNNfu55POHDos3FV2lqbQ+SKVLxiA2480KZq4Q9+hslMJukByYxx+V3tcWgrHGkWf203SOOVVB3dXDn9m3Zyw2aL+gLioIqmuUieQ3jhLLBt8gb34owx48LpaqkPXr8xHsaO32TuhE+uXS7i9gUghV/zwUkQVOG52/m3x5f2so0xYzUOdNWOmNGR2FTGD+7iBQkrMy9lpXrZN3EGQ== common key" \
 --data "net0=name%3Deth0,bridge%3Dvmbr0,hwaddr%3DAA:AA:10:10:$net:$id,ip%3Ddhcp" \
 "$url"api2/json/nodes/profireader/lxc

exit
#    -H "$(<header)" -b "$(<cookie)" \

#curl -s -D/dev/stderr -k \
#    -b "PVEAuthCookie=$TOKEN" \
#    -XPOST \
#    -d hostname=$1 \
#    -d password= \
#    -d ostemplate=local:vztmpl/debian-8.0-standard_8.6-1_amd64.tar.gz \
#    -d vmid=$2 \
#    "$url"/api2/json/nodes/profireader/lxc