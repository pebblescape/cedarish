FROM ubuntu:trusty
MAINTAINER krisrang "mail@rang.ee"

RUN mkdir /tmp/build
ADD ./stack/ /tmp/build
RUN LC_ALL=C DEBIAN_FRONTEND=noninteractive cd /tmp/build && ./build.sh
RUN rm -rf /tmp/build