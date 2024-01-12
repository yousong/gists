FROM debian:buster

#RUN sed -i -e 's:deb\.debian\.org:mirrors.tuna.tsinghua.edu.cn:' /etc/apt/sources.list
RUN apt-get update &&\
    apt-get install -y \
        sudo time git-core subversion build-essential g++ bash make \
        libssl-dev patch libncurses5 libncurses5-dev zlib1g-dev gawk \
        flex gettext wget unzip xz-utils python python-distutils-extra \
        python3 python3-distutils-extra rsync curl libsnmp-dev liblzma-dev \
        libpam0g-dev cpio rsync gcc-multilib && \
    apt-get clean
