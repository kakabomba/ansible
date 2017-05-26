#!/usr/bin/env bash


function usage {
  echo "$0 --config ../inventories/profi.json --id '1201 1202 ...' --status start|stop"
  exit 0
}

id=''
config=''
status=''
template='debian-8.0-standard_8.6-1_amd64.tar.gz'

#eval set -- "$args"
while [ $# -ge 1 ]; do
        case "$1" in
                --)
                    # No more options left.
                    shift
                    break
                   ;;
                --config)
                        config="$2"
                        shift
                        ;;
                --id)
                        id="$2"
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

for thisid in $id; do

    curl --silent --insecure  --cookie "$cookie" --header "$csrftoken" -X DELETE\
     "$url"api2/json/nodes/profireader/lxc/$thisid
    echo ""
    curl --silent --insecure  --cookie "$cookie" --header "$csrftoken" -X DELETE\
     "$url"api2/json/nodes/profireader/qemu/$thisid
    echo ""

done

