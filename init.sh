#!/bin/bash

echo "Enter your domain (e.g. my-podcast.com)"
read domain

echo "Enter the IP of your production host (e.g. 23.48.192.3)"
read prodIp

echo "Enter your admin email (e.g. webmaster@foo.bar)"
read adminEmail

echo "Enter a backup key (empty for random)"
read backupKey
if [ -z "$backupKey" ]; then
  backupKey=$(openssl rand -base64 32)
fi

echo "Enter a mumble password (empty for random)"
read mumbleServerpassword
if [ -z "$mumbleServerpassword" ]; then
  mumbleServerpassword=$(openssl rand -base64 32)
fi

echo "Enter an etherpad user password (empty for random)"
read etherpadUser
if [ -z "$etherpadUser" ]; then
  etherpadUser=$(openssl rand -base64 32)
fi

echo "Enter an etherpad admin password (empty for random)"
read etherpadAdmin
if [ -z "$etherpadAdmin" ]; then
  etherpadAdmin=$(openssl rand -base64 32)
fi

echo "Enter a root mysql password (empty for random)"
read rootDbPassword
if [ -z "$rootDbPassword" ]; then
  rootDbPassword=$(openssl rand -base64 32)
fi

echo "Enter a wordpress mysql password (empty for random)"
read usrWordpressProdPassword
if [ -z "$usrWordpressProdPassword" ]; then
  usrWordpressProdPassword=$(openssl rand -base64 32)
fi

echo "Enter a etherpad mysql password (empty for random)"
read usrEtherpadPassword
if [ -z "$usrEtherpadPassword" ]; then
  usrEtherpadPassword=$(openssl rand -base64 32)
fi

echo "Enter a webstats password (empty for random)"
read webstats
if [ -z "$webstats" ]; then
  webstats=$(openssl rand -base64 32)
fi

echo "Enter a webdav password (empty for random)"
read webdav
if [ -z "$webdav" ]; then
  webdav=$(openssl rand -base64 32)
fi

echo
echo "Domain: $domain"
echo "IP: $prodIp"
echo "Admin email: $adminEmail"
echo "Backup key: $backupKey"
echo "Mumble server pass: $mumbleServerpassword"
echo "Etherpad user pass: $etherpadUser"
echo "Etherpad admin pass: $etherpadAdmin"
echo "Mysql root pass: $rootDbPassword"
echo "Mysql wordpress pass: $usrWordpressProdPassword"
echo "Mysql etherpad pass: $usrEtherpadPassword"
echo "Webstats pass: $webstats"
echo "Webdav pass: $webdav"
echo
echo "Is that right? (yes to proceed)"
read confirm

if [ "$confirm" != "yes" ] && [ "$confirm" != "y" ]; then
  echo "Aborted."
  exit 1;
fi

echo -e "[$domain]\n$prodIp">./production/inventory.ini

echo -e "[$domain]\n192.168.34.2">./staging/inventory.ini

echo "Created inventory files"

mkdir -p roles/certificates/files/etc/letsencrypt

echo "Created empty etc/letsencrypt directory"

sed -i -e 's/rdns:.*/rdns: '$domain'/g' group_vars/all
sed -i -e 's/adminEmail:.*/adminEmail: '$adminEmail'/g' group_vars/all
sed -i -e 's@backup_key:.*@backup_key: '$backupKey'@g' group_vars/all
sed -i -e 's@mumble_serverpassword:.*@mumble_serverpassword: '$mumbleServerpassword'@g' group_vars/all
sed -i -e 's@etherpad_user:.*@etherpad_user: '$etherpadUser'@g' group_vars/all
sed -i -e 's@etherpad_admin:.*@etherpad_admin: '$etherpadAdmin'@g' group_vars/all
sed -i -e 's@root_db_password:.*@root_db_password: '$rootDbPassword'@g' group_vars/all
sed -i -e 's@usr_wordpress_prod_password:.*@usr_wordpress_prod_password: '$usrWordpressProdPassword'@g' group_vars/all
sed -i -e 's@usr_etherpad_password:.*@usr_etherpad_password: '$usrEtherpadPassword'@g' group_vars/all

sed -e '/    name: webstats/{' -e 'n;' -e 's@.*@    pass: '$webstats'@' -e '}' group_vars/all >/tmp/group_vars_all
sed -e '/    name: webdav/{' -e 'n;' -e 's@.*@    pass: '$webdav'@' -e '}' /tmp/group_vars_all >group_vars/all
rm -rf /tmp/group_vars_all

echo "Replaced all variables in group_vars/all"

echo "" | bzip2 | ccrypt -e -K "$backupKey" -f >roles/mysql/files/mysql.sql.bz2

echo "Created empty mysql dump"

mkdir tmp && cd tmp
touch EMPTY
tar cf ../roles/fetch-dynamic-data/files/media.tar *
cd ..
rm -rf tmp
bzip2 roles/fetch-dynamic-data/files/media.tar

echo "Created empty media.tar.bz2"

