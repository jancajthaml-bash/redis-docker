NAME = jancajthaml/redis
VERSION = 3.2

.PHONY: all image strip tag_git tag publish

all: image

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
	docker export $(NAME):$(VERSION) | docker import - $(NAME):stripped

tag: image strip tag_git
	docker tag $(docker images -q $(NAME):stripped) $(NAME):$(VERSION)

publish: tag
	docker push $(NAME)