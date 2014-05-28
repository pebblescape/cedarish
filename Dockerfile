FROM ubuntu:quantal
MAINTAINER krisrang "mail@rang.ee"

ENV DEBIAN_FRONTEND noninteractive
ENV LC_ALL C
ENV INITRD No

RUN mkdir /build
ADD ./build/ /build
RUN cd /build && ./build.sh
RUN rm -rf /build
