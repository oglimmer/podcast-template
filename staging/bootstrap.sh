#!/usr/bin/env bash
curl -s https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub >/home/ubuntu/.ssh/authorized_keys
sudo apt-get update
sudo apt-get -y install python
