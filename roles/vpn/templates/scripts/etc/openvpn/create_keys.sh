#!/usr/bin/env bash

cd /etc/openvpn/
cp -r /usr/share/easy-rsa ./easy-rsa
cd ./easy-rsa
sed -i ./vars  -e 's/\s*export KEY_COUNTRY\s*=\s*".*/export KEY_COUNTRY="UA"/g'
sed -i ./vars  -e 's/\s*export KEY_PROVINCE\s*=\s*".*/export KEY_PROVINCE="Galychyna"/g'
sed -i ./vars  -e 's/\s*export KEY_CITY\s*=\s*".*/export KEY_CITY="Lviv"/g'
sed -i ./vars  -e 's/\s*export KEY_ORG\s*=\s*".*/export KEY_ORG="Ntaxa"/g'
sed -i ./vars  -e 's/\s*export KEY_EMAIL\s*=\s*".*/export KEY_EMAIL="ntaxa@ntaxa.com"/g'
sed -i ./vars  -e 's/\s*export KEY_OU\s*=\s*".*/export KEY_OU=""/g'
./clean-all
"$EASY_RSA/pkitool" --initca
"$EASY_RSA/pkitool" --server server
"$EASY_RSA/pkitool" client
"$OPENSSL" dhparam -out ${KEY_DIR}/dh${KEY_SIZE}.pem ${KEY_SIZE}

cd ./keys/
mkdir ../../keys
cp ./ca.crt ./ca.key ./dh2048.pem ./server.crt ./server.key ./client.crt ./client.key ../../keys

