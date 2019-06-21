#!/usr/bin/env bash

set -o errexit
set -o pipefail

#export CIRCLECI_TOKEN=
#export CIRCLECI_VCS=
#export CIRCLECI_USERNAME=
#export CIRCLECI_PROJECT=
#export CIRCLECI_BUILDNUM=

__circleci_token="$CIRCLECI_TOKEN"
__circleci_vcs="${CIRCLECI_VCS:-github}"
__circleci_username="${CIRCLECI_USERNAME:-openwrt}"
__circleci_project="${CIRCLECI_PROJECT:-packages}"
__circleci_buildnum="${CIRCLECI_BUILDNUM}"

[ -n "$__circleci_token" ]
[ -n "$__circleci_vcs" ]
[ -n "$__circleci_username" ]
[ -n "$__circleci_project" ]
[ -n "$__circleci_buildnum" ]

#
# https://circleci.com/docs/2.0/artifacts/#downloading-all-artifacts-for-a-build-on-circleci
#
url_artifacts="https://circleci.com/api/v1.1/project/$__circleci_vcs/$__circleci_username/$__circleci_project/$__circleci_buildnum/artifacts?circle-token=$__circleci_token"

dl() {
	curl "$url_artifacts" \
		| tee artifacts.json \
		| jq -r '.[].url' - \
		| tee artifacts.txt \
		| while read f; do
			echo " -c -O '$(basename "$f")' '$f'"
		done \
		| tee artifacts.sh \
		| xargs -P8 -L1 wget
	#<artifacts.txt xargs -P8 -I % wget %
	#<artifacts.txt xargs -P8 -I % bash -c "exec wget -O \$(basename %) -c '%?circle-token=$__circleci_token'"

}

"$@"
