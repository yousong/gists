FROM quay.io/jupyter/pytorch-notebook:x86_64-cuda12-2024-11-18

ENV \
	NVIDIA_DRIVER_CAPABILITIES=all

USER root
RUN set -ex \
	&& apt-get update \
	&& apt-get install -y git \
	&& apt install -y vulkan-tools libegl1 libxext6 \
	&& apt clean \
	&& sed -i -e "s:archive\.ubuntu\.com:mirrors.tuna.tsinghua.edu.cn:" /etc/apt/sources.list.d/ubuntu.sources \
	&& true

USER jovyan
RUN set -ex \
	&& mkdir -p $HOME/.pip \
	&& echo '[global]' >$HOME/.pip/pip.conf \
	&& echo 'index-url = https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple' >>$HOME/.pip/pip.conf \
	&& echo 'disable-pip-version-check = true' >>$HOME/.pip/pip.conf \
	&& true
