NAME = jancajthaml/redis
VERSION = latest

.PHONY: all image tag upload publish

all: image

image:
	docker build -t $(NAME):stage .
	docker export $$(docker ps -q -n=1) | docker import - $(NAME):stripped
	docker tag $(NAME):stripped $(NAME):$(VERSION)
	docker rmi $(NAME):stripped
	docker rmi $(NAME):stage

tag: image
	git checkout -B release/$(VERSION)
	git add --all
	git commit -a --allow-empty-message -m '' 2> /dev/null || :
	git rebase --no-ff --autosquash release/$(VERSION)
	git pull origin release/$(VERSION) 2> /dev/null || :
	git push origin release/$(VERSION)
	git checkout -B master

run:
	docker run --rm -it --log-driver none $(NAME):$(VERSION) redis-server /etc/redis.conf

squash:
	docker export $(NAME) | docker import - $(NAME):$(VERSION)

upload:
	docker login -u jancajthaml https://index.docker.io/v1/
	docker push $(NAME)

publish: image tag upload