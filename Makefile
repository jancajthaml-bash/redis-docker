NAME = jancajthaml/redis
VERSION = latest

.PHONY: all image tag upload publish

all: image

image:
	docker build -t $(NAME):$(VERSION) .

tag: image
	git checkout -B release/$(VERSION)
	git add --all
	git commit -a --allow-empty-message -m '' 2> /dev/null || true
	git rebase --no-ff --autosquash release/$(VERSION)
	git pull origin release/$(VERSION) 2> /dev/null || true
	git push origin release/$(VERSION)
	git checkout -B master

run: image
	docker run --rm -it --log-driver none $(NAME):$(VERSION)

upload:
	docker login -u jancajthaml https://index.docker.io/v1/
	docker push $(NAME)

publish: image tag upload