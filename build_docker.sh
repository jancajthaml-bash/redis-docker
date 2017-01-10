
port="6379"
volume="/data"
user="redis"

run_tests=false

cat <<EOF > Dockerfile
FROM alpine:latest

MAINTAINER Jan Cajthaml <jan.cajthaml@gmail.com>

ENV S6_OVERLAY_VERSION v1.17.1.1
ENV GODNSMASQ_VERSION 0.9.8

RUN addgroup -S ${user} && \\
    adduser -S -G ${user} ${user}

RUN apk add --no-cache --virtual linux-headers && \\
    apk add --no-cache --virtual tcl && \\
    apk add --no-cache --virtual curl && \\
    apk add --no-cache --virtual build-base

RUN curl -sSL https://github.com/just-containers/s6-overlay/releases/download/\${S6_OVERLAY_VERSION}/s6-overlay-amd64.tar.gz \\
    | tar xvfz - -C / && \\
    curl -sSL https://github.com/janeczku/go-dnsmasq/releases/download/\${GODNSMASQ_VERSION}/go-dnsmasq-min_linux-amd64 -o /bin/go-dnsmasq && \\
    chmod +x /bin/go-dnsmasq

RUN wget http://download.redis.io/redis-stable.tar.gz && \\
    mkdir -p /tmp/redis-stable && \\
    tar -xzf redis-stable.tar.gz -C /tmp/redis-stable --strip-components=1 && \\
    rm -rf redis-stable.tar.gz && \\
    cd /tmp/redis-stable && \\
    grep -q '^#define CONFIG_DEFAULT_PROTECTED_MODE 1\$' src/server.h && \\
    sed -ri 's!^(#define CONFIG_DEFAULT_PROTECTED_MODE) 1\$!\1 0!' src/server.h && \\
    grep -q '^#define CONFIG_DEFAULT_PROTECTED_MODE 0\$' src/server.h && \\
    make
EOF

$run_tests && cat <<EOF >> Dockerfile

RUN cd /tmp/redis-stable && \\
    rm tests/integration/aof.tcl && \\
    rm tests/integration/logging.tcl && \\
    mv tests/test_helper.tcl tests/test_helper.tcl.ORIG && \\
    egrep -v 'integration/(aof|logging)' tests/test_helper.tcl.ORIG > tests/test_helper.tcl && \\
    rm tests/test_helper.tcl.ORIG && \\
    make test
EOF

cat <<EOF >> Dockerfile

RUN cd /tmp/redis-stable && \\
    make install && \\
    rm -rf /tmp/redis-stable

RUN apk del linux-headers && \\
    apk del tcl && \\
    apk del curl && \\
    apk del build-base && \\
    rm -rf /var/cache/*

RUN apk info

# Add the files
ADD etc /etc
ADD usr /usr

# Remove comment to lower size
RUN a=\$(sed -e '/^[[:space:]]*\$/d' -e '/^[[:space:]]*#/d' /etc/redis.conf);echo "\$a" > /etc/redis.conf

# Local to broadcast
RUN sed -i -e 's/bind 127.0.0.1/bind 0.0.0.0/' /etc/redis.conf

RUN mkdir -p ${volume} && \\
    mkdir -p /var/lib/redis && \\
    mkdir -p /var/log/redis && \\
    chown -R ${user}:${user} ${volume} && \\
    chown -R ${user}:${user} /var/lib/redis && \\
    chown -R ${user}:${user} /var/log/redis/

VOLUME ["${volume}"]

# Expose the ports for redis
EXPOSE ${port}

ENTRYPOINT ["/init"]
CMD []
EOF

[ $(uname) == "Darwin" ] && command -v docker-machine > /dev/null 2>&1 && {
  docker-machine ssh $(docker-machine active) "sudo udhcpc SIGUSR1 && sudo /etc/init.d/docker restart"
}

make image
