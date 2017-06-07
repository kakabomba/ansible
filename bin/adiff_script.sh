#!/usr/bin/env bash


function usage {
  echo "$0 inventory host --remote file --local file"
  exit 0
}

inventory=${1?'pls set inventory (-h for help)'}
host=${2?'pls set host (-h for help)'}
shift
shift
while [ $# -ge 1 ]; do
        case "$1" in
                --)
                    # No more options left.
                    shift
                    break
                   ;;
                --remote)
                        remote="$2"
                        shift
                        ;;
                --local)
                        local="$2"
                        shift
                        ;;
               -h)
                    usage
                    ;;
        esac

        shift
done


echo "diff ${remote?'pls set --remote'} at $host in $inventory with ${local?'pls set --local'}"


varansible=$(ansible -i $inventory -m debug -a "var=hostvars['$host']" $host)


varjson=$(echo $varansible | tr '\n' ' ' | sed -e 's/\s\+//g' | sed -e 's/.*|SUCCESS=>//' )


host_port=$(echo $varjson | python3 -c "import sys, json; i=json.load(sys.stdin); l=lambda x: i[\"hostvars['$host']\"][x]; print(l('ansible_host'), l('ansible_port'))")

scp -P$(echo $host_port | cut -d ' ' -f2) root@$(echo $host_port | cut -d ' ' -f1)":$remote" /tmp/$(basename $remote)

echo '!!!!'

colordiff --side-by-side --suppress-common-lines -W240 "$local" "/tmp/$(basename $remote)"

