#!/bin/bash

topdir="$(dirname $(readlink -f $0))/../.."

log() {
	echo "$*" >&2
}

build_and_push() {
	local d="$1"; shift

	cd "$d"
	if ! test -s "$d/docker-build-env"; then
		log "build_and_push: $d: skipping (missing env file)"
		return
	fi
	unset DOCKER_IMAGE_TAG
	source "$d/docker-build-env"
	if test -z "$DOCKER_IMAGE_TAG"; then
		log "build_and_push: $d: skipping (empty or null \$DOCKER_IMAGE_TAG)"
		return
	fi
	if test "$GITHUB_REF" = "refs/heads/testing"; then
		log "build_and_push: $d: build testing image"
		DOCKER_IMAGE_TAG="${DOCKER_IMAGE_TAG%:*}:testing-${DOCKER_IMAGE_TAG#*:}"
	fi
	log "build_and_push: $d: building $DOCKER_IMAGE_TAG"
	docker build -t "$DOCKER_IMAGE_TAG" .
	docker image push "$DOCKER_IMAGE_TAG"
}

build_and_push_all() {
	cd "$topdir"
	for d in docker/*; do
		build_and_push "$topdir/$d"
	done
}

set -o errexit
set -o xtrace

build_and_push_all
