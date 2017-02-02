# Setting up the server

## Prerequisites

Install via your favorite package manager on your local machine:

* ccrypt
* ansible
* virtualbox
* vagrant
* bzip2
* openssl

## General notes

* All passwords are defined in `./group_vars/all`. There it you can modify them via calling init.sh or editing the file manually.
* The IP address of the prod server is defined in `./production/inventory.ini` which can be set via init.sh as well.
* This script was tested on **Ubuntu 16.04.** While newer Ubuntu versions probably work as well, other Linux distros or older Ubuntu version probably don't work.
* Optionally you can install a collectd which sends data to a remote graphite host. You need to configure this target graphite host in group_vars/all with the variable graphitehost and you need to uncomment the lines in the collectd section in roles/stats/tasks/main.yml

## Deployment use-cases

1. Set up a completely new system
2. Clone a system into a new system (like prod to staging)
3. Update an already installed system

## 1.) Set up a completely new system

This involves many automated and manual steps, the order of the following steps are important.

This section covers the intial first set up of your server, so we start with calling init.sh to set variables and create those base files.

### Create some salts for wordpress

Go to the [Salt-generator](https://api.wordpress.org/secret-key/1.1/salt/) and generate a set of php statements. Open the file `./roles/wordpress/files/wp-config.php` and replace snippet.


### Using init.sh to create config

Start with calling

`./init.sh`

and answer all questions.

### Initial deploment via ansible

The initial deployment will finally fail when it tries to start the haproxy. This is normal as you don't have any SSL certificate files.

#### On a host provided by an 'Internet hosting service'

Installing all components by executing this from your local host:

`./deploy.sh production site`

#### On a local VM via vagrant/virtualbox

If you don't have a host on the internet yet or just want to play around with this, start a local VM by executing the following commands from your local host.

This will start a local VM:

`cd staging && vagrant up && cd ..`

Installing all components by executing this from your local host:

`./deploy.sh staging site`

(Hint: To ssh into the VM use `ssh -i /tmp/vagrant.key ubuntu@192.168.34.2`)

### Getting SSL certificates from letsencrypt

**This works only if your server is reachable from the internet and you have already set up DNS properly. If this is not the case skip to the next paragraph.**

After setting up the server for the first time, you need to log into ssh and execute the certbot-auto.

It is important that the haproxy is not running. Therefore stop it:

`sudo service haproxy stop`

Assuming you have already configured DNS for your 
Then you can request the SSL certificates. Take the following command, but make sure to replace all 'yourdomain.com' with your actual domain first:

`sudo certbot-auto certonly -d yourdomain.com -d www.yourdomain.com -d notes.yourdomain.com -d transfer.yourdomain.com --standalone`

Now start the haproxy:

`sudo service haproxy start`

### Setting up insecure SSL certificates for a local VM

If you cannot get a proper SSL certificate from letsencrypt (because you are running on a host not reachable from the internet or because you haven't set up DNS yet) then you can create a self-signed certificate.

Execute the following commands on the host and enter your domain when it asks for `Common Name (e.g. server FQDN or YOUR name) []`:

```
sudo mkdir -p /etc/letsencrypt/live/YOUR_DOMAIN
cd /etc/letsencrypt/live/YOUR_DOMAIN
sudo openssl req -x509 -newkey rsa:4096 -keyout privkey.pem -out fullchain.pem -days 365 -nodes
sudo bash -c 'cat fullchain.pem privkey.pem >fullchainandkey.pem'
sudo service haproxy restart
```

To test your new local VM you need to alter your DNS settings, so you are able to use the real domain (for which the SSL certificate is issued).

Add the following line to /etc/hosts:

`192.168.34.2 YOUR_DOMAIN `

This will send all requests for YOUR-DOMAIN to the local VM.

Use use a browser and go to http://YOUR_DOMAIN

**DO NOT FORGET TO REMOVE THE ENTRY IN /etc/hosts AFTER TESTING!!!**

### Wordpress plugin for SSL behind a proxy

Now you should be able to browse to your domain. You should see the Wordpress installation wizard. Follow all steps.

As we want to run the apache behind a haproxy, we need to install this [wordpress plugin](https://blog.virtualzone.de/2016/08/howto-https-ssl-wordpress-behind-proxy-nginx-haproxy-apache-lighttpd.html).

If you have done that, open the file roles/haproxy/templates/haproxy.cfg on your local machine and uncomment the line `redirect scheme https if ! { ssl_fc }`. After that execute `./deploy.sh [staging|production] site` to update the change.

### Set up a backup

You can get 15GB of backup space for free at google.

Go to https://console.developers.google.com and enable Drive API and Drive SDK (in API manager).
Create a new "Client ID for native application" (with a client-id).
This should give you a CLIENT_ID and a CLIENT_SECRET. Put both into `/etc/backup-config`.

Then execute `google_auth.sh create`. Take the `Refresh Token` and add it to `/etc/backup-config` as `REFRESH_TOKEN`.

Finally you need the ID of a folder. So create a folder in https://drive.google.com and get the ID from the URL. But that into `/etc/backup-config` as `GOOGLE_DRIVE_FOLDER`.

These entries should reside inside `/etc/backup-config`. Here is an example:

```
GOOGLE_DRIVE_FOLDER=....
CLIENT_ID="...."
CLIENT_SECRET="...."
REFRESH_TOKEN=....
```

Now add additional entries to `/etc/backup-config`:

```
MYSQL=true
CONFIG=true
MEDIA=true
WORDPRESS=true
```

These 4 entires will enable backups for the different sources.


### Enable email (which is disabled by default)

`sudo touch /etc/mailenabled` to enable email sending, Without a file /etc/mailenabled the smtp daemon postfix won't start. Restart your server with `sudo reboot`.

### configure DKIM signatures for sending emails
 
The file `/etc/opendkim/keys/mail.txt` has the content for a DNS TXT entry to sign outgoing emails.

### configure additional email addresses

The file `roles/postfix/templates/aliases.j2` on your local machine, stores all email addresses and the forward email address.

To add another email forward simple add a line to the file and re-run the deploy.sh script.

## 2.) Clone a system into a new system

To set up a clone, because you want to move your production host or you want to set up a testing host, you first need to retrieve the base files aka a backup fromt he current production system.

### Retrieve backup

The command `./deploy.sh production fetch-dynamic-data` will retrieve 

- /etc/letsencrypt
- /var/www/wordpress/wp-content
- /var/www/media
- /var/lib/mumble-server/mumble-server.sqlite

from the server and readies them for re-deployment

### Re-deploment

Either start a local VM or just change the IP in the production/inventory.ini to deploy the backup to a new host.

## 3.) Update an already installed system

Just use

`./deploy.sh [staging|production] site`

to update a host.


## 4.) Parameters for deploy.sh

### `-u`

Add `-u` to do an `apt-get update && apt-get upgrade` during the ansible run

`./deploy.sh -u production site`

### `-n`

Add `-n` to do skip all sub deployment routines and just deploy changes in wordpress, mumble or etherpad.

`./deploy.sh -n production site`

# Setting up the website

## Media share at /mp3

The webserver shares your media files via https://YOUR_DOMAIN/mp3/

To upload files on the server, use a WebDav client and connect to https://transfer.YOUR_DOMAIN/media with the user 'webdav' and the password you provided during the initial setup. 

## Wordpress Podlove plugin

The Podlove plugin is the next generation podcast publishing system.

See [their website](https://wordpress.org/plugins/podlove-podcasting-plugin-for-wordpress/) for details, but you can install it via the plugin system in the admin area of wordpress.

## Your feed URL

Your podcast feed will be available from https://YOUR_DOMAIN/feed/mp3/ This URL needs to be used when registering your podcast.

## The logo

The logo should have 3000x3000 pixel with a transparent background.

## Forget the feed validators

There are many feed validators (like https://validator.w3.org/feed/) out there, but here is my advice: just ignore them. Podlove works, so there is no real need to validate your feed and as the feed validators spill out many errors and warning, you just get confused.

## HTTPS works

There are tons of comments which say `https doesn't work` or `letsencrypt doesn't work`. Forget it. The setup used within this Ansible script works - with https from letsencrypt.

## Recording a podcast

You can use the mumber-server installed within this Ansible script to record your podcast. Mumble can natively record a session, even with separated audio files for each participant. You can download a client for Windows, macOS or Linux from [here](http://www.mumble.com/mumble-download.php).

## GoMumbleSoundboard

Check out [GoMumbleSoundboard](https://github.com/robbi5/gomumblesoundboard) to play sound snippets.

## Adding your podcast to iTunes

To register an iTunes podcast you need have a Apple-ID and then go to https://podcastsconnect.apple.com/ where you can submit your podcast feed.

iTunes is a bit picky about file formats, so your feed need to have m4a audio files and they need to be encoded as AAC. There are many ways to get a properly encoded m4a/aac file, but this one works for sure:

Drop your mp3 / wav file into iTunes and convert it via menu "File" -> "Convert" -> "Create AAC Version". While doing so you can also edit the meta data of the file.

## Adding your podcast to Tunein

To register at Tunein go [here](http://help.tunein.com/customer/portal/emails/new?ticket[labels_new]=podcast&t=641867) and fill out the form. They will reply via email (and we had to re-submit the logo via email ;) )

## Adding your podcast to player.fm

Register at [player.fm](http://player.fm) and submit your podcast.
