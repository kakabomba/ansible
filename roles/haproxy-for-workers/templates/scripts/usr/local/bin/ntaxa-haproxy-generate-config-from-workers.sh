#!/bin/bash

cd /usr/local/bin/

source /usr/local/bin/o-lib.sh

run_script_only_once

f=150
t=200
ch="a-zA-Z0-9_-"
onel="\\(\\(\\([$ch]\\{1,30\\}\\)\\|\\(\\*\\)\\)\\.\\)"
a="^$onel*\\([$ch]\\{1,30\\}\\.\\)[$ch]\\{1,10\\}\$"
newl="
"
__deb ()
{ 
  echo "$*" 1>&2
} 

backend_name () {
  echo $external_domain-$1
}

html ()
{
  vma=$1
  hna=$2
  ipa=$3
  alsa=$4
  echo "ServerName $hna$alsa" > "$external_ip_dirweb/$vma/$hna"
  return 0
}

ip_for_domain () {
  __deb '-> ip_for_domain'" $*"
  local ret=$(host -ta $1 | grep 'has address' | head -n1 | sed -e 's/.* has address //g')
  __deb '<- ip_for_domain'" $ret"
  echo $ret
}

if_fqdn_and_our_ip () {
  __deb '->'" if_fqdn_and_our_ip $*"
  local ret=''
  local ifip=$1
  local d=''
  shift
  for d in $*; do
    local d_ip=$(ip_for_domain $d)
    if is_fqdn $d; then 
      if [[ "$d_ip" == "$ifip" ]]; then
        ret="$ret $d"
      else
        __deb "domain $d has wrong ip ($d_ip != $ifip) ignored"
      fi
    else
        __deb "domain $d is not fqdn. ignored"
    fi
  done
  __deb '<-'" if_fqdn_and_our_ip $ret"
  echo $ret
}

generate_certificate () {
  __deb '->'" generate_certificate $*"
  local ssltype=$1
  local certdir=$2
  local ifip=$3
  local proj_name=$4
  local domains="${@:5}"
  local d=''
  local last_cert_timestamp='0'
  local now_timestamp=''
  local from_last_cert_timestamp=''
  if [[ "$ssltype" == 'no' ]]; then
    return 
  fi
  if [[ "$ssltype" == 'auto' ]]; then
    ssl_domains=$(if_fqdn_and_our_ip $ifip $domains)
    for d in $ssl_domains; do
      __deb "Invoking ./cert_for_domains.sh $d"
      chainkey=$(./cert_for_domains.sh $d)
      if [[ "$chainkey" == "" ]]; then
        __deb "No chain. we will try to get by letsencrypt"
        last_cert_timestamp=$(file_timestamp /usr/local/bin/haproxy_templates/last_cert_timestamp_$d)
        now_timestamp=$(date +"%s")
        from_last_cert_timestamp=$(( $now_timestamp - $last_cert_timestamp ))
        if [[ $from_last_cert_timestamp < 3600 ]]; then
          __deb "Last certificate was retrieved less than hour ($from_last_cert_timestamp). waiting"
        else
          $(./certonly.sh ntaxa@ntaxa.com $d)
          touch /usr/local/bin/haproxy_templates/last_cert_timestamp_$d
          chainkey=$(./cert_for_domains.sh $d)
        fi
      fi
      fullchain=$(echo "$chainkey" | grep 'Certificate Path: ' | sed -e 's/^.*:\s\+//g')
      privkey=$(echo "$chainkey" | grep 'Private Key Path: ' | sed -e 's/^.*:\s\+//g')
      if [[ -f $fullchain && -f $privkey ]]; then
        cat $fullchain $privkey > "$certdir"/"$project_name"_"$d".pem
      fi
    done
  fi
  if [[ "$ssltype" == 'yes' ]]; then
    fullchain_privkey="$(ssh -i /root/.ssh/haproxy_worker_communication_id_rsa -oBatchMode=yes $ip /usr/local/bin/ntaxa-apache-list-projects.sh $proj_name)"
    cat $fullchain_privkey > "$certdir/$project_name.pem"
  fi
  __deb '<-'" generate_certificate"
}

generate_redirections () {
  local ssltype=$1
  local redirect=$2
  local external_ip=$3
  local p_n=$4
  local domains="${@:5}"
  local d
  local tohttp="$external_ip_dir/$ip/to_http_redirection.cfg"
  local tohttps="$external_ip_dir/$ip/to_https_redirection.cfg"
  local conditionlines=''
  local conditions=''
  local aliasconditin=''
  for d in $domains; do
    if [[ "$d" =~ [*] ]] ; then
      aliasconditin='hdr_reg(host) -i ^'$(echo $d | sed -e 's/\./\\./gi' -e 's/\*/.*/gi')'$'
    else
      aliasconditin="hdr(host) -i $d"
    fi
	if [[ ${#conditions} -gt 150 ]]; then
      conditionlines="$conditionlines$newl$conditions"
      conditions=''
    fi
      conditions="$conditions or { $aliasconditin }"
  done
  conditionlines=$(strip_new_lines "$conditionlines$newl$conditions")
  if [[ "$conditionlines" != "" && $conditions != "" && $redirect == "yes"  ]]; then
    if [[ "$ssltype" == 'auto' || "$ssltype" == 'yes' ]]; then
      echo "
# project $p_n" >> $tohttps
      echo "$conditionlines" | sed -e "s/^ or /    redirect scheme https code 301 if !{ ssl_fc } !lets_encrypt_request /gi" >> $tohttps
    else
      echo "
# project $p_n" >> $tohttp
      echo "$conditionlines" | sed -e "s/^ or /    redirect scheme http code 301 if { ssl_fc } /gi" >> $tohttp
    fi
  fi
} 

generate_use_backend ()
{
  local ip=$1
  local p_n=$2
  local alsa=$3
  local alias=''
  usebackendfile="$external_ip_dir/$ip/use_backend.cfg"
  conditionlines=''
  conditions=''
  for alias in $alsa; do
    if [[ "$alias" =~ [*] ]] ; then
      aliasconditin='hdr_reg(host) -i ^'$(echo $alias | sed -e 's/\./\\./gi' -e 's/\*/.*/gi')'$'
    else
      aliasconditin="hdr(host) -i $alias"
    fi
	if [[ ${#conditions} -gt 150 ]]; then
      conditionlines="$conditionlines$newl$conditions"
      conditions=''
    fi
      conditions="$conditions or { $aliasconditin }"
  done
  conditionlines=$(strip_new_lines "$conditionlines$newl$conditions")
  if [[ "$conditionlines" != "" ]]; then
    echo "
# project $p_n" >> $usebackendfile
    echo "$conditionlines" | sed -e "s/^ or /    use_backend $(backend_name $ip) if /gi" >> $usebackendfile
  fi
}

append_from () {
   local dir=$1
   local ip=$2
   local filename=$3
   if [[ -f $dir/$ip/$filename  ]]; then
     echo "
#from file $dir/$ip/$filename" >> $dir/$filename
    cat $dir/$ip/$filename >> $dir/$filename
   fi
}

copy_from () {
   local dir=$1
   local ip=$2
   local dirname=$3
   mkdir -p $dir/$dirname
   for f in $(ls $dir/$ip/$dirname); do
      cp $dir/$ip/$dirname/$f $dir/$dirname/"$ip"_"$f"
   done
}

replace_by_file () {
 sed "/$1/ {
  r $2
  d
}"
}

replace_by_string () {
 sed -e "s/$1/$2/g"
}


newl="
"   
rootdir="/usr/local/bin/haproxy"
rm -r "$rootdir/"*
ip_net_domain_sets='88.99.238.13:10.10.13.:md5.ntaxa.com'
#ip_net_domain_sets='88.99.238.13:10.10.13.:md5.ntaxa.com'
#allcertsdir="$rootdir/certs"
for ip_net_domain in $ip_net_domain_sets; do
  read external_ip internal_net external_domain < <(echo $ip_net_domain | sed -e 's/:/ /g')
  echo "checking $external_ip $internal_net $external_domain"
  external_ip_dir="$rootdir/$external_ip"
  mkdir -p $external_ip_dir
  for ipnum in {0..99}; do
    ip=$internal_net$ipnum
    vmid=$(echo $internal_net | sed -e 's/10\.10\.\([[:digit:]]\{2,2\}\)\./\1/g')$(printf "%02d" $ipnum)
    __deb checking ip $ip
    host_is_up $ip
    if [[ $? == '1' ]]; then
      echo "    host $ip is up"
      mkdir -p $external_ip_dir/$ip
      certdir=$external_ip_dir/$ip/certs
      mkdir -p $certdir
      mkdir -p $external_ip_dirweb/$ip
      projects="$(ssh -i /root/.ssh/haproxy_worker_communication_id_rsa -oBatchMode=yes $ip /usr/local/bin/ntaxa-apache-list-projects.sh)"
      generate_use_backend $ip "$vmid"."$external_domain" "$vmid"."$external_domain"
      if [[ "$projects" != "" ]]; then
        echo "$projects" | sed -e 's/[[:alpha:]]\+:/ /g' | while read -r project_name ssltype domains; do
          echo "        project: $project_name"
          echo "          domains: $domains"
          echo "          ssltype: $ssltype"
          generate_use_backend $ip $project_name "$domains"
          generate_certificate $ssltype $external_ip_dir/$ip/certs $external_ip $project_name "$domains"
#          generate_redirections $ssltype $redirect $external_ip $project_name "$domains"
        done
      else
        __deb there is no ssh connection to host or no projects there
      fi
      echo "backend $(backend_name $ip)
    http-response set-header X-VM $ip
    server $external_domain-$ip $ip:80" > $external_ip_dir/$ip/backend.cfg
    else
      __deb host is down
      echo "    host $ip is down"
    fi
  done

  for ip in $(ls $external_ip_dir/); do
    __deb ip is $ip
    append_from $external_ip_dir $ip backend.cfg
    append_from $external_ip_dir $ip use_backend.cfg
#    append_from $external_ip_dir $ip to_http_redirection.cfg
#    append_from $external_ip_dir $ip to_https_redirection.cfg
    copy_from $external_ip_dir $ip certs
  done
cat ./haproxy_templates/haproxy.frontend.cfg.template \
  | replace_by_file '----use_backends----' $external_ip_dir/use_backend.cfg \
  | replace_by_string '----port_http----' "80" \
  | replace_by_string '----port_https----' "443" \
  | replace_by_string '----external_ip----' "$external_ip" \
  > $external_ip_dir/frontend.cfg
#  | replace_by_file '----to_http_redirections----' $external_ip_dir/to_http_redirection.cfg \
#  | replace_by_file '----to_https_redirections----' $external_ip_dir/to_https_redirection.cfg \
done

for external_ip in $(ls $rootdir/); do
  __deb "external_ip is $external_ip"
  append_from $rootdir $external_ip backend.cfg
  append_from $rootdir $external_ip frontend.cfg
  mkdir -p $rootdir/certs/$external_ip
  echo '/etc/haproxy/certs/default.pem' > $rootdir/certs/$external_ip/certs.txt
  if [[ -d $rootdir/$external_ip/certs/ ]]; then
    for cert in $(ls $rootdir/$external_ip/certs/); do
      echo "/etc/haproxy/certs/$external_ip/$cert" >> $rootdir/certs/$external_ip/certs.txt
      cp $rootdir/$external_ip/certs/$cert $rootdir/certs/$external_ip/$cert
    done
  fi
done
cp ./haproxy_templates/default.pem $rootdir/certs/default.pem

cat ./haproxy_templates/haproxy.cfg.template \
  | replace_by_file "----haproxy_end----" ./haproxy_templates/haproxy_begin.cfg \
  | replace_by_file "----backends----" $rootdir/backend.cfg \
  | replace_by_file '----frontends----' $rootdir/frontend.cfg \
  | replace_by_file "----haproxy_end----" ./haproxy_templates/haproxy_end.cfg \
  > $rootdir/haproxy.cfg

md5oldcerts=$(md5_dir /etc/haproxy/certs) 
md5newcerts=$(md5_dir $rootdir/certs) 
md5oldconf=$(md5_file /etc/haproxy/haproxy.cfg) 
md5newconf=$(md5_file $rootdir/haproxy.cfg) 
__deb "[[ $md5newcerts != $md5oldcerts ]] || [[ $md5newconf != $md5oldconf ]]"
echo ''
if [[ $md5newcerts != $md5oldcerts ]] || [[ $md5newconf != $md5oldconf ]]; then
  echo syncing certs copy haproxy.cfg and restarting haproxy
  rsync -r --force --del $rootdir/certs/ /etc/haproxy/certs/
  cp $rootdir/haproxy.cfg /etc/haproxy/haproxy.cfg
  /usr/sbin/service haproxy restart
else
  echo "certificates nor configs didn't changed" 
fi

