#!/bin/bash

exec 2>&1
set -e
set -x

cat > /etc/apt/sources.list <<EOF
deb http://archive.ubuntu.com/ubuntu trusty main
deb http://archive.ubuntu.com/ubuntu trusty-security main
deb http://archive.ubuntu.com/ubuntu trusty-updates main
deb http://archive.ubuntu.com/ubuntu trusty universe
deb http://archive.ubuntu.com/ubuntu trusty-updates universe
EOF

apt-get update

xargs apt-get install -y --force-yes < packages.txt

# initctl hack
dpkg-divert --local --rename --add /sbin/initctl
sh -c "test -f /sbin/initctl || ln -s /bin/true /sbin/initctl"

# install ruby 2.1.2
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

# jemalloc
mkdir /jemalloc && cd /jemalloc
wget http://www.canonware.com/download/jemalloc/jemalloc-3.4.1.tar.bz2
tar -xvjf jemalloc-3.4.1.tar.bz2 && cd jemalloc-3.4.1 && ./configure && make
mv lib/libjemalloc.so.1 /usr/lib && cd / && rm -rf /jemalloc

locale-gen en_US

# clean apt
cd /
rm -rf /var/cache/apt/archives/*.deb
rm -rf /var/lib/apt/lists/*
rm -rf /root/*
rm -rf /tmp/*

apt-get clean

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