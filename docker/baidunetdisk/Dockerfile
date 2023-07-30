FROM jlesage/baseimage-gui:debian-11-v4.4

ENV HOME=/config
ENV TZ=Asia/Shanghai
ENV LC_ALL=C

ARG BAIDUNETDISK_VERSION=4.17.7

ADD root/ /

RUN set -x \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends \
		ca-certificates \
		curl \
		libasound2 \
		libdrm2 \
		libgbm1 \
		libx11-xcb1 \
		ttf-wqy-zenhei \
		xdg-utils \
	&& curl -o baidunetdisk.deb https://issuepcdn.baidupcs.com/issue/netdisk/LinuxGuanjia/${BAIDUNETDISK_VERSION}/baidunetdisk_${BAIDUNETDISK_VERSION}_amd64.deb \
	&& apt-get install -y --no-install-recommends ./baidunetdisk.deb \
	&& rm -vf baidunetdisk.deb \
	&& install_app_icon.sh /baidunetdisk.png \
	&& set-cont-env APP_NAME "百度网盘" \
	&& set-cont-env APP_VERSION "$BAIDUNETDISK_VERSION" \
	&& rm -rf /var/lib/apt/lists/* \
	&& true
