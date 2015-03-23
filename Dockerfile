FROM ubuntu:trusty
MAINTAINER krisrang "mail@rang.ee"

ENV DEBIAN_FRONTEND noninteractive
ENV LC_ALL C
ENV INITRD No

ADD ./build /build
RUN /build/build.sh

CMD ["/usr/bin/runsvdir", "-P", "/etc/service"]