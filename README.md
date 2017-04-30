Compact redis container ( 20.3MB / 8MB compressed )

## Stack

Build from source of [Redis 3.2](https://redis.io/download) running on top of lightweight [Alphine Linux](https://alpinelinux.org).

## Usage

`docker run --rm -it --log-driver none jancajthaml/redis:latest redis-server /etc/redis.conf`
