FROM alpine:latest

MAINTAINER Jan Cajthaml <jan.cajthaml@gmail.com>

ENV S6_OVERLAY_VERSION v1.17.1.1
ENV GODNSMASQ_VERSION 0.9.8

RUN addgroup -S redis && \
    adduser -S -G redis redis

RUN apk add --no-cache --virtual linux-headers && \
    apk add --no-cache --virtual tcl && \
    apk add --no-cache --virtual curl && \
    apk add --no-cache --virtual build-base

RUN curl -sSL https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_VERSION}/s6-overlay-amd64.tar.gz \
    | tar xvfz - -C / && \
    curl -sSL https://github.com/janeczku/go-dnsmasq/releases/download/${GODNSMASQ_VERSION}/go-dnsmasq-min_linux-amd64 -o /bin/go-dnsmasq && \
    chmod +x /bin/go-dnsmasq

RUN wget http://download.redis.io/redis-stable.tar.gz && \
    mkdir -p /tmp/redis-stable && \
    tar -xzf redis-stable.tar.gz -C /tmp/redis-stable --strip-components=1 && \
    rm -rf redis-stable.tar.gz && \
    cd /tmp/redis-stable && \
    grep -q '^#define CONFIG_DEFAULT_PROTECTED_MODE 1$' src/server.h && \
    sed -ri 's!^(#define CONFIG_DEFAULT_PROTECTED_MODE) 1$!\1 0!' src/server.h && \
    grep -q '^#define CONFIG_DEFAULT_PROTECTED_MODE 0$' src/server.h && \
    make

RUN cd /tmp/redis-stable && \
    make install && \
    rm -rf /tmp/redis-stable

RUN apk del linux-headers && \
    apk del tcl && \
    apk del curl && \
    apk del build-base && \
    rm -rf /var/cache/*

RUN apk info

# Add the files
ADD etc /etc
ADD usr /usr

# Remove comment to lower size
RUN (grep  -v ^# /etc/redis.conf | grep -v ^$) > /etc/redis.conf

# Local to broadcast
RUN sed -i -e 's/bind 127.0.0.1/bind 0.0.0.0/' /etc/redis.conf

RUN mkdir -p /data && \
    mkdir -p /var/lib/redis && \
    mkdir -p /var/log/redis && \
    chown -R redis:redis /data && \
    chown -R redis:redis /var/lib/redis && \
    chown -R redis:redis /var/log/redis/

VOLUME ["/data"]

# Expose the ports for redis
EXPOSE 6379

ENTRYPOINT ["/init"]
CMD []
