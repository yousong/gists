dockerBuildName=yousong/sphinx-latexpdf-extra
dockerBuildTag=0.0.2

docker-image-build:
	docker build \
		-t $(dockerBuildName):$(dockerBuildTag) \
		-f Dockerfile-latexpdf-extra \
		.
	docker tag $(dockerBuildName):$(dockerBuildTag) $(dockerBuildName):latest

docker-image-push:
	docker image push $(dockerBuildName):$(dockerBuildTag)
	docker image push $(dockerBuildName):latest
