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

	unset DOCKER_IMAGE_TAGS
	source "$d/docker-build-env"

	local tag
	local built_tag
	for tag in "${DOCKER_IMAGE_TAGS[@]}"; do
		if test "$GITHUB_REF" = "refs/heads/testing"; then
			log "build_and_push: $d: build testing image"
			tag="${tag%:*}:testing-${tag#*:}"
		fi
		if test -z "$built_tag"; then
			log "build_and_push: $d: build and push $tag"
			docker build -t "$tag" .
			docker image push "$tag"
			built_tag="$tag"
		else
			log "build_and_push: $d: tagg and push $tag"
			docker tag "$built_tag" "$tag"
			docker image push "$tag"
		fi
	done

	if test -z "$built_tag"; then
		log "build_and_push: $d: nothing built (empty or null \$DOCKER_IMAGE_TAGS)"
	fi
}

build_and_push_all() {
	local d

	cd "$topdir"
	for d in docker/*; do
		build_and_push "$topdir/$d"
	done
}

set -o errexit
set -o xtrace

build_and_push_all
