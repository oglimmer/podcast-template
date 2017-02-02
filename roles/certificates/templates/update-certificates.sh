#!/bin/bash

export PATH=$PATH:/sbin:/usr/sbin

service haproxy stop

/usr/local/bin/certbot-auto renew

cp /etc/letsencrypt/live/{{ rdns }}/fullchain.pem /etc/mumble-server/
cp /etc/letsencrypt/live/{{ rdns }}/privkey.pem /etc/mumble-server/
cat /etc/letsencrypt/live/{{ rdns }}/fullchain.pem /etc/letsencrypt/live/{{ rdns }}/privkey.pem >/etc/letsencrypt/live/{{ rdns }}/fullchainandkey.pem

service mumble-server restart
service haproxy start

