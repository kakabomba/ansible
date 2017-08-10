#!/usr/bin/env bash


function usage {
  echo "$0 --config ../inventories/profi.json --id "2014 3056 ..." [--hostname hahaha] [--size 5] [--onboot 0|1] [--memory 0|1] "
  exit 0
}

id=''
onboot=''
config=''
size=''
hostname=''

i=0
args=()

add_data() {
    args[$i]="--data"
    ((++i))
    args[$i]="$1=$2"
    ((++i))
}


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
                --onboot)
                        add_data onboot $2
                        shift
                        ;;
                --memory)
                        add_data memory $2
                        shift
                        ;;
                --size)
                        add_data rootfs "!!rootfsvol!!,size%3D$2"
                        shift
                        ;;
                --hostname)
                        add_data hostname $2
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

#echo curl --silent --insecure  --cookie "$cookie" --header "$csrftoken" -X POST "${args[@]}"\
# "$url"api2/json/nodes/profireader/lxc/$id/config

for thisid in $id; do
    olddata=$(curl --insecure --cookie "$cookie" --header "$csrftoken" -X GET "$url"api2/json/nodes/profireader/lxc/$thisid/config 2>/dev/null)
    echo $olddata
    rootfsvol=$(echo $olddata | jq --raw-output  '.data.rootfs' | sed -e 's/^\([^,]*\),.*/\1/g')
    args=$(echo "${args[@]}" | sed -e "s/!!rootfsvol!!/$rootfsvol/g")
    echo "$args"
    curl --insecure --cookie "$cookie" --header "$csrftoken" -X PUT $args "$url"api2/json/nodes/profireader/lxc/$thisid/config
    curl --insecure --cookie "$cookie" --header "$csrftoken" -X GET "$url"api2/json/nodes/profireader/lxc/$thisid/config
    echo ""
done
