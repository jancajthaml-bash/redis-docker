NAME = jancajthaml/redis
VERSION = 3.2

.PHONY: all image strip tag_git tag publish

all: image

stage:
	docker build -t $(NAME):stage .

image:
	docker build -t $(NAME):$(VERSION) .

tag_git:
	git checkout -B release/$(VERSION)
	git branch --set-upstream-to=origin/release/$(VERSION) release/$(VERSION)
	git pull --tags
	git add --all
	git commit -a --allow-empty-message -m ''
	git rebase --no-ff --autosquash release/$(VERSION)
	git push origin release/$(VERSION)

strip:
	docker export $$(docker ps -q -n=1) | docker import - $(NAME):stripped

tag: stage strip tag_git
	docker tag $(NAME):stripped $(NAME):$(VERSION)

publish: tag
	docker push $(NAME)