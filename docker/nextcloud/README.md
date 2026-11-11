Originally copied from https://github.com/nextcloud/docker

  .examples/dockerfiles/full/apache/Dockerfile

Update instructions: https://github.com/nextcloud/docker?tab=readme-ov-file#update-to-a-newer-version

## Maintenance

Upgrades are automated with `docker/nextcloud/bin/nc-upgrade` (run `docker/nextcloud/bin/nc-upgrade help`).
It resolves the repo root itself, so it works from any working directory — the path
below assumes the repo root:

    docker/nextcloud/bin/nc-upgrade status            # current vs latest, recent CI runs
    docker/nextcloud/bin/nc-upgrade upgrade           # full chain to latest, one build per major
    docker/nextcloud/bin/nc-upgrade bump 34 && docker/nextcloud/bin/nc-upgrade commit 34 && docker/nextcloud/bin/nc-upgrade trigger

Each step bumps `Dockerfile` + `docker-build-env` together, commits on branch
`nc`, pushes, dispatches `.github/workflows/docker-build-and-push.yaml` via the
GitHub API (needs a fine-grained PAT with "Actions: write", from env
`NC_UPGRADE_TOKEN` or the gitignored `docker/nextcloud/.nc-upgrade-token` —
this repo is public, never commit tokens), then
watches the run and dumps failed job logs. Only one major version per step is
possible since Nextcloud can only upgrade one major at a time.
