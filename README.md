Compact redis container ( 25.94MB / 10MB compressed )

## Stack

Build from source of [Redis 3.2](https://redis.io/download) running on top of lightweight [Alphine Linux](https://alpinelinux.org) with services managed by [S6](http://git.skarnet.org/cgi-bin/cgit.cgi/s6/about/) suite.

## Usage

`docker run --rm -it --log-driver none $(NAME):$(VERSION) redis-server /etc/redis.conf`

public image from dockerHub `docker pull jancajthaml/redis`
