NAME = jancajthaml/redis
VERSION = 3.2

.PHONY: all image tag

all: image

image:
	docker build -t $(NAME):$(VERSION) --no-cache .

tag_test:
	git checkout -B release/$(VERSION)
	git fetch --tags
	git add --all
	git commit -a --allow-empty-message -m ''
	git rebase release/$(VERSION) --skip
	git push

tag:
	docker tag -f $(NAME):$(VERSION) $(NAME):latest

publish:
	docker push $(NAME)