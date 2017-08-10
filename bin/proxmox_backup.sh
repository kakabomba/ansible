#!/usr/bin/env bash


function usage {
  echo "$0 --config ../inventories/profi.json --id '1201 1202 ... | all' --status start|stop"
  exit 0
}

id=''
config=''

#eval set -- "$args"
while [ $# -ge 1 ]; do
        case "$1" in
                --)
                    # No more options left.
                    shift
                    break
                   ;;
                --id)
                        id="$2"
                        shift
                        ;;
                --config)
                        config="$2"
                        shift
                        ;;
                -h)
                    usage
                    ;;
        esac

        shift
done


if [[ "$id" == "" || "$config" == "" ]]; then
  usage
fi

usr=$(cat $config | jq -r .username)
pass=$(cat $config | jq -r .password)
url=$(cat $config | jq -r .url)

up="username=$usr&password=$pass"
cookie=$(curl --silent --insecure --data "$up"  "$url"api2/json/access/ticket | jq --raw-output '.data.ticket' | sed 's/^/PVEAuthCookie=/')
csrftoken=$(curl --silent --insecure --data "$up" "$url"api2/json/access/ticket | jq --raw-output '.data.CSRFPreventionToken' | sed 's/^/CSRFPreventionToken:/')

if [[ "$id" == 'all' ]]; then
  echo "getting all_ips"
  id=$(curl --silent --insecure  --cookie "$cookie" --header "$csrftoken" -X GET "$url"api2/json/nodes/profireader/qemu | jq -r .data |  grep '^\s*"vmid":' | sed -e 's/^\s*"vmid":\s*"\?\([0-9]\+\).*$/\1/g' | xargs)
  id="$id "$(curl --silent --insecure  --cookie "$cookie" --header "$csrftoken" -X GET "$url"api2/json/nodes/profireader/lxc | jq -r .data |  grep '^\s*"vmid":' | sed -e 's/^\s*"vmid":\s*"\?\([0-9]\+\).*$/\1/g' | xargs)
fi

for thisid in $id; do
  echo "backuping $thisid"
  curl --insecure --cookie "$cookie" --header "$csrftoken" -X POST "$url"api2/json/nodes/profireader/$thisid/vzdump \
        --data "snapname=aaa$thisid"
done

