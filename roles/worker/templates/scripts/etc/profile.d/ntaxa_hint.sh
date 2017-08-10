#!/bin/bash

#hostname=`hostname`
#domain=$(cat /etc/resolv.conf | grep 'domain ' | sed -e's/^[[:space:]]*domain[[:space:]]\+//')
#echo ''
#echo ''
read net ip < <(/sbin/ifconfig | grep 'inet addr:10.10.' | sed "s/.*addr:10.10.\([[:digit:]]\{1,3\}\).\([[:digit:]]\{1,3\}\).*/\1 \2/")

case $net in
12)
  domain='oleh'
  ;;
13)
  domain='md5'
  ;;
14)
  domain='yurko'
  ;;
*)
  echo
  echo "!!!!!!!!!!!!!!!!! You have wrong ip. please check your mac address  !!!!!!!!!!!"
  exit
  ;;
esac
myip=$(printf "%02d" $ip)
hostname=$net$myip

echo
echo "-- Hello $domain --"
echo ""
echo "--   ssh	: ssh $domain.ntaxa.com -p 22$myip"
echo "--   ftp	: ftp $domain.ntaxa.com 21$myip"
echo "--   mysql	: http://$hostname.$domain.ntaxa.com/mysql/"
echo "--   postgres	: http://$hostname.$domain.ntaxa.com/postgres/"

echo "--   useful tools:"

for t in /usr/local/bin/ntaxa-*; do
  echo "--   "`basename $t`":		"`$t -h`
done
