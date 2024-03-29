set -x

i=yousong/test:testing-gocryptfs-2.4.0

mkdir -p c p
if ! test -s "p/.gocryptfs.reverse.conf"; then
	docker run --rm -it -v /dev/fuse:/dev/fuse --privileged -v $PWD/c:/c -v $PWD/p:/p $i -init -reverse /p
fi
docker run --rm -it --device /dev/fuse --cap-add sys_admin -v $PWD/c:/c:shared -v $PWD/p:/p:ro -v $PWD/passfile:/passfile:ro $i -fg -allow_other -nosyslog -reverse -passfile /passfile /p /c
