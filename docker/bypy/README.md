# the container
container environment variable

	RUN_CRONTAB    path to crontab file within container.  It will be processed with `crontab` command

docker run example

	docker run --rm -it \
		-v $PWD/_bypy:/root/.bypy \
		yousong/test:bypy \
		info

	# put crontab lines in side $PWD/crontabs
	docker run --rm -it \
		-v $PWD/_bypy:/root/.bypy \
		-v $PWD/crontabs:/crontabs \
		-e RUN_CRONTAB=/crontabs \
		yousong/test:bypy

# bypy

## quickstart

	# https://github.com/houtianze/bypy
	bypy info # trigger auth, stored at $HOME/.bypy
	bypy ls
	bypy syncup localdir remotedir
	bypy syncup localdir remotedir True # delete remote
	bypy syncdown remotedir localdir
	bypy --downloader aria2 syncdown remotedir localdir

## auth

Bypy uses device auth by default.  The api key and secret are defined in const.py file.  Use the following environment variables to override it

	BAIDU_API_KEY
	BAIDU_API_SECRET

It's also hardcoded in const.py that AppPcsPath be `/apps/bypy`.

Config files including auth result are located at `$HOME/.bypy/`
