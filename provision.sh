#!/bin/bash
if [ -e "/etc/.provisioned" ] ; then
  echo "VM already provisioned.  Remove /etc/.provisioned to force"
  exit 0
fi

apt-get -qq update
DEBIAN_FRONTEND=noninteractive apt-get -qq install -y python-software-properties git-core linux-image-extra-`uname -r` lxc wget
echo deb https://get.docker.io/ubuntu docker main > /etc/apt/sources.list.d/docker.list
apt-get -qq update
DEBIAN_FRONTEND=noninteractive apt-get install -y --force-yes lxc-docker
service docker restart
usermod -a -G docker vagrant

touch /etc/.provisioned