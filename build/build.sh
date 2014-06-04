#!/bin/bash

exec 2>&1
set -e
set -x

# apt_get_install='apt-get install -y --no-install-recommends'
apt_get_install='apt-get install -y'

## Temporarily disable dpkg fsync to make building faster.
echo force-unsafe-io > /etc/dpkg/dpkg.cfg.d/02apt-speedup

## Install packages
sed -i 's/^#\s*\(deb.*universe\)$/\1/g' /etc/apt/sources.list
sed -i 's/^#\s*\(deb.*multiverse\)$/\1/g' /etc/apt/sources.list
apt-get update

$apt_get_install apt-transport-https ca-certificates
xargs apt-get install -y --force-yes < packages.txt

## Upgrade all packages
apt-get dist-upgrade -y #--no-install-recommends

## Fix some issues with APT packages.
## See https://github.com/dotcloud/docker/issues/1024
dpkg-divert --local --rename --add /sbin/initctl
ln -sf /bin/true /sbin/initctl

## Replace the 'ischroot' tool to make it always return true.
## Prevent initscripts updates from breaking /dev/shm.
## https://journal.paul.querna.org/articles/2013/10/15/docker-ubuntu-on-rackspace/
## https://bugs.launchpad.net/launchpad/+bug/974584
dpkg-divert --local --rename --add /usr/bin/ischroot
ln -sf /bin/true /usr/bin/ischroot

## Install ruby 2.1.2-discourse
echo 'gem: --no-document' >> /usr/local/etc/gemrc
mkdir /src && cd /src && git clone https://github.com/sstephenson/ruby-build.git
cd /src/ruby-build && ./install.sh
cd / && rm -rf /src/ruby-build
echo install_package "yaml-0.1.6" "http://pyyaml.org/download/libyaml/yaml-0.1.6.tar.gz#5fe00cda18ca5daeb43762b80c38e06e" --if needs_yaml > /src/2.1.2.discourse
echo install_package "openssl-1.0.1g" "https://www.openssl.org/source/openssl-1.0.1g.tar.gz#de62b43dfcd858e66a74bee1c834e959" mac_openssl --if has_broken_mac_openssl >> /src/2.1.2.discourse
echo install_package "ruby-v_2_1_2_discourse" "https://github.com/SamSaffron/ruby/archive/v_2_1_2_discourse.tar.gz#98741e3cbfd00ae2931b2c0edb0f0698" ldflags_dirs standard verify_openssl >> /src/2.1.2.discourse
apt-get -y install ruby bison
ruby-build /src/2.1.2.discourse /usr/local
apt-get -y remove ruby1.8
gem update --system
gem install bundler

## jemalloc
mkdir /jemalloc && cd /jemalloc
wget http://www.canonware.com/download/jemalloc/jemalloc-3.4.1.tar.bz2
tar -xvjf jemalloc-3.4.1.tar.bz2 && cd jemalloc-3.4.1 && ./configure && make
mv lib/libjemalloc.so.1 /usr/lib && cd / && rm -rf /jemalloc

## docker client
wget https://get.docker.io/builds/Linux/x86_64/docker-latest -O /usr/local/bin/docker
chmod +x /usr/local/bin/docker

## Fix locale.
$apt_get_install language-pack-en
locale-gen en_US

## Install runit.
$apt_get_install runit

## Install a syslog daemon.
$apt_get_install syslog-ng-core
mkdir /etc/service/syslog-ng
cp /build/runit/syslog-ng /etc/service/syslog-ng/run
mkdir -p /var/lib/syslog-ng
cp /build/config/syslog_ng_default /etc/default/syslog-ng
# Replace the system() source because inside Docker we
# can't access /proc/kmsg.
sed -i -E 's/^(\s*)system\(\);/\1unix-stream("\/dev\/log");/' /etc/syslog-ng/syslog-ng.conf

## Install logrotate.
$apt_get_install logrotate

## Install cron daemon.
$apt_get_install cron
mkdir /etc/service/cron
cp /build/runit/cron /etc/service/cron/run

## Remove useless cron entries.
# Checks for lost+found and scans for mtab.
rm -f /etc/cron.daily/standard

## Often used tools.
$apt_get_install curl less nano vim psmisc

## Cleanup
apt-get clean
rm -rf /build
rm -rf /tmp/* /var/tmp/*
rm -rf /var/lib/apt/lists/*
rm -f /etc/dpkg/dpkg.cfg.d/02apt-speedup

rm -f /etc/ssh/ssh_host_*

cd /

# remove SUID and SGID flags from all binaries
function pruned_find() {
  find / -type d \( -name dev -o -name proc \) -prune -o $@ -print
}

pruned_find -perm /u+s | xargs -r chmod u-s
pruned_find -perm /g+s | xargs -r chmod g-s

# remove non-root ownership of files
chown root:root /var/lib/libuuid

# display build summary
set +x
echo -e "\nRemaining suspicious security bits:"
(
  pruned_find ! -user root
  pruned_find -perm /u+s
  pruned_find -perm /g+s
  pruned_find -perm /+t
) | sed -u "s/^/  /"

echo -e "\nInstalled versions:"
(
  git --version
  java -version
  ruby -v
  gem -v
  python -V
) | sed -u "s/^/  /"


echo -e "\nSuccess!"
exit 0