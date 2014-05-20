FROM phusion/baseimage
MAINTAINER krisrang "mail@rang.ee"

# Set correct environment variables.
ENV HOME /root

# Regenerate SSH host keys. baseimage-docker does not contain any, so you
# have to do that yourself. You may also comment out this instruction; the
# init system will auto-generate one during boot.
RUN /etc/my_init.d/00_regen_ssh_host_keys.sh

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

# Add packages and ruby
RUN mkdir /tmp/build
ADD ./stack/ /tmp/build
RUN cd /tmp/build && ./build.sh
RUN rm -rf /tmp/build
