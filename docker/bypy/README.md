bypy quickstart

	# https://github.com/houtianze/bypy
	bypy info # trigger auth, stored at $HOME/.bypy
	bypy ls
	bypy syncup localdir remotedir
	bypy syncup localdir remotedir True # delete remote
	bypy syncdown remotedir localdir
	bypy --downloader aria2 syncdown remotedir localdir

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
