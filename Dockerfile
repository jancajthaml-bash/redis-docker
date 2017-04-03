FROM        alpine:latest

MAINTAINER  Jan Cajthaml <jan.cajthaml@gmail.com>

ENV         S6_OVERLAY_VERSION v1.18.1.5 \
            GODNSMASQ_VERSION 1.0.7

RUN         addgroup -S redis && \
            adduser -S -G redis redis

RUN         set -x && \
            apk add --update libcap && \
            apk add --no-cache --virtual .build-deps \
            curl \
            linux-headers \
            tcl \
            build-base

RUN         curl -sSL https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_VERSION}/s6-overlay-amd64.tar.gz | \
            tar xvfz - -C / && \
            curl -sSL https://github.com/janeczku/go-dnsmasq/releases/download/${GODNSMASQ_VERSION}/go-dnsmasq-min_linux-amd64 -o /bin/go-dnsmasq && \
            addgroup go-dnsmasq && \
            adduser -D -g "" -s /bin/sh -G go-dnsmasq go-dnsmasq && \
            setcap CAP_NET_BIND_SERVICE=+eip /bin/go-dnsmasq

RUN         wget http://download.redis.io/redis-stable.tar.gz && \
            mkdir -p /tmp/redis-stable && \
            tar -xzf redis-stable.tar.gz -C /tmp/redis-stable --strip-components=1 && \
            rm -rf redis-stable.tar.gz && \
            cd /tmp/redis-stable && \
            grep -q '^#define CONFIG_DEFAULT_PROTECTED_MODE 1$' src/server.h && \
            sed -ri 's!^(#define CONFIG_DEFAULT_PROTECTED_MODE) 1$!\1 0!' src/server.h && \
            grep -q '^#define CONFIG_DEFAULT_PROTECTED_MODE 0$' src/server.h && \
            make

RUN         cd /tmp/redis-stable && \
            make -C /tmp/redis-stable \
            install && \
            rm -rf /tmp/redis-stable

RUN         runDeps="$( \
                scanelf --needed --nobanner --recursive /usr/local \
                | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
                | sort -u \
                | xargs -r apk info --installed \
                | sort -u \
            )" && \
            apk add --virtual .haproxy-rundeps $runDeps && \
            apk del .build-deps

ADD         etc /etc
ADD         usr /usr

RUN         a=$(sed -e '/^[[:space:]]*$/d' -e '/^[[:space:]]*#/d' /etc/redis.conf);echo "$a" > /etc/redis.conf
RUN         sed -i -e 's/bind 127.0.0.1/bind 0.0.0.0/' /etc/redis.conf

RUN         mkdir -p /data && \
            mkdir -p /var/lib/redis && \
            mkdir -p /var/log/redis && \
            chown -R redis:redis /data && \
            chown -R redis:redis /var/lib/redis && \
            chown -R redis:redis /var/log/redis/

VOLUME      ["/data"]
EXPOSE      6379

ENTRYPOINT  ["/init"]
CMD         []
