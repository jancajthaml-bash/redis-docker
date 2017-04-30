FROM alpine:latest

MAINTAINER Jan Cajthaml <jan.cajthaml@gmail.com>

COPY        etc /etc

RUN         addgroup -S redis && \
            adduser -D -S -h /var/cache/redis -s /sbin/nologin -G redis redis && \
            apk upgrade --update && \
            apk --update --no-cache add libcap \
                                        linux-headers \
                                        tcl \
                                        wget \
                                        build-base && \
            wget http://download.redis.io/redis-stable.tar.gz && \
            mkdir -p /tmp/redis-stable && \
            tar -xzf redis-stable.tar.gz -C /tmp/redis-stable --strip-components=1 && \
            rm -rf redis-stable.tar.gz && \
            grep -q '^#define CONFIG_DEFAULT_PROTECTED_MODE 1$' /tmp/redis-stable/src/server.h && \
            sed -ri 's!^(#define CONFIG_DEFAULT_PROTECTED_MODE) 1$!\1 0!' /tmp/redis-stable/src/server.h && \
            grep -q '^#define CONFIG_DEFAULT_PROTECTED_MODE 0$' /tmp/redis-stable/src/server.h && \
            make -C /tmp/redis-stable -j$(getconf _NPROCESSORS_ONLN) && \
            make -C /tmp/redis-stable -j$(getconf _NPROCESSORS_ONLN) install && \
            apk --purge del linux-headers tcl wget build-base && \
            rm -rf /tmp/redis-stable && \
            rm -rf /var/cache/apk/* && \
            mkdir -p /data && \
            mkdir -p /var/lib/redis && \
            mkdir -p /var/log/redis && \
            chown -R redis:redis /data && \
            chown -R redis:redis /var/lib/redis && \
            chown -R redis:redis /var/log/redis/ && \
            sed -i -e 's/bind 127.0.0.1/bind 0.0.0.0/;/^[[:space:]]*$/d;/^[[:space:]]*#/d' /etc/redis.conf

VOLUME ["data"]

EXPOSE 6379

STOPSIGNAL SIGQUIT

CMD ["redis-server", "/etc/redis.conf"]