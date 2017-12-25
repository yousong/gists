CC:=gcc
CROSS_COMPILE:=$(HOME)/git-repo/lede-project/lede/staging_dir/toolchain-x86_64_gcc-5.4.0_musl/bin/x86_64-openwrt-linux-musl-
CROSS_COMPILE:=

all: _udpio.so echoserver.tar.gz

_udpio.so: _udpio.c
	$(CROSS_COMPILE)$(CC) -o $@ -D_GNU_SOURCE -shared -fPIC $^

DEPS_echoserver.tar.gz = echoserver.py udpio.py _udpio.so
echoserver.tar.gz: $(DEPS_echoserver.tar.gz)
	tar czf $@ $^


clean:
	@rm -vf _udpio.so
	@rm -vf echoserver.tar.gz
