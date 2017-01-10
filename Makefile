NAME = jancajthaml/redis
VERSION = 3.2

.PHONY: all image tag_git tag publish

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

tag: image tag_git
	docker tag -f $(NAME):$(VERSION)

publish: tag
	docker push $(NAME)