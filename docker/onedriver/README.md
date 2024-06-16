It provides a variant of [headless onedriver](https://github.com/jstaf/onedriver)

# How to use it

Note that `$cacheDir` is actually a parent dir for the per mount point dir
(`/mnt` in the following example)

```sh
cacheDir="$HOME/j/c"
mountDir="$HOME/j/m"

docker run --rm -it \
	-v "$cacheDir:/cache" \
	-v "$mountDir:/mnt:shared" \
	--device /dev/fuse \
	--cap-add sys_admin \
	r:t \
	--cache-dir "/cache" \
	--allow-other \
	--uid `id -u` \
	--gid `id -g` \
	/mnt
```
