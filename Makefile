NAME = jancajthaml/redis
VERSION = 3.2

.PHONY: all image tag_git tag publish clean

all: image clean

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
	docker export $$(docker ps -q -n=1) | docker import - $(NAME):stripped
	docker tag $(NAME):stripped $(NAME):$(VERSION)
	docker rmi $(NAME):stripped

publish: tag
	docker push $(NAME)
	clean

clean:
	docker images | grep -i "^<none>" | awk '{ print $$3 }' | \
		xargs -P$$(getconf _NPROCESSORS_ONLN) -I{} docker rmi -f {}
	orphans=$$(docker volume ls -qf dangling=true)
	[ $$($$orphans | wc -l) -gt 0 ] && docker volume rm $$orphans || true