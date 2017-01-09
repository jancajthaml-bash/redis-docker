FROM alpine:latest

MAINTAINER Jan Cajthaml <jan.cajthaml@gmail.com>

ENV S6_OVERLAY_VERSION v1.17.1.1
ENV GODNSMASQ_VERSION 0.9.8

RUN apk add --no-cache linux-headers && \
    apk add --no-cache tcl && \
    apk add --no-cache curl && \
    apk add --no-cache build-base

RUN curl -sSL https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_VERSION}/s6-overlay-amd64.tar.gz \
    | tar xvfz - -C / && \
    curl -sSL https://github.com/janeczku/go-dnsmasq/releases/download/${GODNSMASQ_VERSION}/go-dnsmasq-min_linux-amd64 -o /bin/go-dnsmasq && \
    chmod +x /bin/go-dnsmasq

RUN wget http://download.redis.io/redis-stable.tar.gz && \
    tar xvzf redis-stable.tar.gz && \
    cd redis-stable && \
    make

RUN cd redis-stable && \
    (false && \
    rm tests/integration/aof.tcl && \
    rm tests/integration/logging.tcl && \
    mv tests/test_helper.tcl redis-stable/tests/test_helper.tcl.ORIG && \
    egrep -v 'integration/(aof|logging)' tests/test_helper.tcl.ORIG > tests/test_helper.tcl && \
    rm tests/test_helper.tcl.ORIG && \
    make test) || true

RUN cd redis-stable && \
    make install

RUN apk del linux-headers && \
    apk del tcl && \
    apk del curl && \
    apk del build-base && \
    rm -rf /var/cache/apk/*

RUN apk info

# Add the files
ADD etc /etc
ADD usr /usr

RUN sed -i -e 's/bind 127.0.0.1/bind 0.0.0.0/' /etc/redis.conf

RUN adduser -D redis

RUN mkdir -p /data && \
    mkdir -p /var/lib/redis && \
    chown -R redis:redis /data && \
    chown -R redis:redis /var/lib/redis

VOLUME ["/data"]

# Expose the ports for redis
EXPOSE 6379

ENTRYPOINT ["/init"]
CMD []
