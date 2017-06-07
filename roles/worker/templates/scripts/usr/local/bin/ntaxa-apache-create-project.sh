#!/bin/bash

if [[ "$1" == "-h" ]] || [[ $# -ne 1 ]]; then
    echo "Usage: "`basename "$0"`" host.name 
create host files in /var/www/host.name with aliases (www.)host.name. Apache use conf file /var/www/hostname/conf/main.conf
"
    exit
fi


proj=$1

di="/var/www/$1"
if [ -d "$di" ]; then
    echo "Error. directory $di exists"
    exit
fi

mkdir "$di"
mkdir "$di/web/"
mkdir "$di/log/"
mkdir "$di/tmp/"
mkdir "$di/config/"
mkdir "$di/config/ssl"

confd="$di/config"
#echo 'auto' > "$confd"/redirect

echo "ServerName $proj" > "$confd/aliases.conf"
echo "ServerAlias www.$proj" >> "$confd/aliases.conf"

#ln -s /etc/apache2/vhost/root.conf $confd/root.conf
#ln -s /etc/apache2/vhost/cgi.conf $confd/cgi.conf
#ln -s /etc/apache2/vhost/proxy.conf $confd/proxy.conf
ln -s /etc/apache2/vhost/web.conf $confd/web.conf

cp /var/www/host.php $di/web/index.php

#chown www-data:www-data -R "$di"
touch "/var/log/apache2/access-$proj.log";
touch "/var/log/apache2/error-$proj.log";
ln -s /var/log/apache2/access-$proj.log $di/log/access.log
ln -s /var/log/apache2/error-$proj.log $di/log/error.log

echo 'reading vhost template files'

saveIFS="$IFS"
IFS='
'
vhost=`cat /etc/apache2/vhost/main.tpl`

sfile=''

for line in $vhost; do
  line=$(echo "$line" | sed "s/%project%/$proj/g")
  sfile="$sfile$line"'\n'
done

#newfile="/etc/apache2/sites-available/$proj.conf"

#if [ -f $newfile ]; then
#  echo "file $newfile' exists!!!. Copying to '/tmp/$proj.conf.bak'"
#  cp $newfile "/tmp/$proj.conf.bak"
#fi

echo -e $sfile > "$confd/main.conf"
ln -s "$confd/main.conf" /etc/apache2/sites-enabled/$proj.conf

chown www-data:www-data -R $di

#/usr/local/bin/apache-update-proxy-by-aliases.sh $confd/aliases.conf

service apache2 restart

echo "Please wait a fem minutes untill proxy server sync aliases.
All aliases (ServerName and ServerAliases) from $di/config/aliases*.config goes to proxy server every few minutes"

cd $di
ls
