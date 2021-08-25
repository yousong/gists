FROM fedora:34

RUN dnf install -y \
	acl attr automake bc dbench dump e2fsprogs fio \
	gawk gcc indent libtool lvm2 make psmisc quota sed \
	xfsdump xfsprogs \
	libacl-devel libaio-devel libuuid-devel \
	xfsprogs-devel btrfs-progs-devel python sqlite liburing-devel \
	libcap-devel

RUN dnf install -y \
	hostname \
	patch

COPY ./xfstests-2021-08-16-ae8c30c34c51b5a5c5dd1639ec83ef901a40b3ad.tar.gz /root/xfstests.tar.gz
RUN set -x \
	&& cd /root \
	&& find . -type f | xargs -r ls -l \
	&& tar xzf xfstests.tar.gz \
	&& mv xfstests-* xfstests \
	&& cd ./xfstests \
	&& make -j$(nproc) \
	&& true
