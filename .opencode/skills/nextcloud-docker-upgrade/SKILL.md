---
name: Nextcloud Docker Upgrade
description: Upgrade, rebuild, or triage the custom full Nextcloud image in docker/nextcloud (yousong/test:nextcloud-*-full on Docker Hub, branch "nc", workflow docker-build-and-push.yaml). Use whenever the user asks for a newer Nextcloud image, wants the nextcloud docker build (re)triggered on GitHub Actions, asks to check or fix a failed nextcloud image build, or mentions bumping/upgrading the nextcloud Dockerfile base tag — even if they don't say "docker" explicitly.
---

# Upgrading the custom full Nextcloud image

Everything deterministic lives in `docker/nextcloud/bin/nc-upgrade` (run `nc-upgrade help`).
Prefer its subcommands over hand-editing files or calling the GitHub API ad hoc —
they validate versions against Docker Hub, guard the one-major-per-step rule,
stage exactly the right files, resolve the dispatched run id, and fetch failure logs.

## What the image is

- `docker/nextcloud/Dockerfile`: `FROM nextcloud:N-apache` plus extra packages
  (ffmpeg, ghostscript, smbclient, supervisor, bz2, php smbclient via pecl).
  Derived from nextcloud/docker's `.examples/dockerfiles/full/apache/Dockerfile`.
- `docker/nextcloud/docker-build-env`: `DOCKER_IMAGE_TAGS` — a versioned tag
  `yousong/test:nextcloud-N-full` and the floating `yousong/test:nextcloud-full`.
- CI: `.github/workflows/docker-build-and-push.yaml` (`workflow_dispatch` inputs
  `dirs="docker/nextcloud"`, `is_testing`) builds and pushes to Docker Hub
  using the repo's `DOCKERHUB_USERNAME`/`DOCKERHUB_TOKEN` secrets.
- Work happens on branch **nc**; the container runs with `NEXTCLOUD_UPDATE=1`
  and upgrades its data directory when deployed.

## Why one major version per build

Nextcloud supports upgrading **only one major version at a time**. Reaching N
from N-2 requires building and deploying the N-1 image first. So a chain like
33 → 35 is two complete round-trips, never a single commit that skips 34.
`nc-upgrade bump` refuses >+1 jumps unless `--force`; `nc-upgrade upgrade [N]`
walks the chain, one bump-commit-push-build per step, stopping on the first
build failure.

## Runbook

1. `docker/nextcloud/bin/nc-upgrade status`
   — current vs latest upstream, branch/tree state, recent CI runs.
2. Preview the whole plan: `... upgrade --dry-run [N]` (N defaults to latest).
3. Per step (the `upgrade` loop does these in sequence; do them manually when a
   step is expected to need Dockerfile fixes):
   - `... bump M` — checks Docker Hub for `nextcloud:M-apache`, edits both
     files, prints the diff for review.
   - `... commit [M] [extra message text...]` — stages **only** the two files
     and commits `docker/nextcloud: upgrade to M`. Version-only bumps need no
     extra text; when the Dockerfile needed real changes (removed extension,
     renamed package…), pass a short explanation so it lands in the commit body.
   - `... trigger` — pushes `nc` (refuses on divergence), dispatches the
     workflow with `dirs=docker/nextcloud`, resolves the run, watches it, and
     on failure dumps the tail of every failed job's log. `--testing` builds
     `testing-`-prefixed tags instead; `--no-wait` returns the run id only.
4. If a step fails: read the dumped log (or `... fail-log [run-id]`),
   propose/apply Dockerfile or env fixes as an ordinary commit or fold them
   into the step, re-run `trigger`. Then continue the chain.

## Failure triage notes (learned from this repo's history)

Base-image OS upgrades break this Dockerfile periodically; check
`git log --oneline -- docker/nextcloud` for precedents before theorizing.

- A `-dev`/`libc-*` package "not found" during `apt-get install`, or a
  `docker-php-ext-configure/install` failure: the Debian in the new base may
  have dropped/renamed the package (e.g. libc-client-dev gone in Debian 13
  trixie forced removing the PHP imap extension — commit 56b90fc). Removing
  the affected extension from the Dockerfile is an acceptable fix; say so in
  the commit body.
- Missing runtime library for a PHP module (`libmagickcore-*` style):
  often now shipped by the base image or by a renamed `*-q16-*` package —
  try dropping the explicit install first.
- Anything about upstream's example Dockerfile changing: diff against
  <https://github.com/nextcloud/docker/blob/master/.examples/dockerfiles/full/apache/Dockerfile>.
- Transient Docker Hub/apt network failures: just re-run `trigger`.
- Known workflow quirk: `docker-build-and-push.sh` mis-tests the `ALL` dirs
  default (`$DOCKER_IMAGE_TAGS` instead of `$DOCKER_BUILD_AND_PUSH_DIRS`), so
  never dispatch with `dirs=ALL`; `nc-upgrade trigger` always passes the
  explicit directory.

## Safety (this repository is public)

- Never put tokens, Docker Hub credentials, or secrets into the repo, commits,
  or issue/CI transcripts you paste here. `nc-upgrade` reads its GitHub token
  only from env vars or the gitignored `docker/nextcloud/.nc-upgrade-token`.
- Only commit via `nc-upgrade commit` (it stages exactly the two build files);
  never `git add -A`. Only push the `nc` branch. The build itself is triggered
  through the GitHub API by `trigger` — a plain push to `nc` does NOT build.

## One-time setup for `trigger`/`watch`

A GitHub token with **Actions: write** on `yousong/gists` (fine-grained PAT is
enough). Either export it as `NC_UPGRADE_TOKEN`/`GITHUB_TOKEN`, or save it as
the only line of `docker/nextcloud/.nc-upgrade-token` (gitignored; chmod 600).
Reads (`status`) work without it.
