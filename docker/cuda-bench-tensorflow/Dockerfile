FROM tensorflow/tensorflow:1.15.5-gpu-py3

ENV \
	TF_FORCE_GPU_ALLOW_GROWTH=true \
	TF_CPP_MIN_LOG_LEVEL=2 \
	PYTHONUNBUFFERED=1

RUN set -ex \
	&& apt-key adv --keyserver keyserver.ubuntu.com --recv-keys A4B469963BF863CC \
	&& apt-get update \
	&& apt-get install -y git \
	&& cd / \
	&& git clone --single-branch --branch=cnn_tf_v1.15_compatible --depth=1 https://github.com/tensorflow/benchmarks.git
WORKDIR /benchmarks/scripts/tf_cnn_benchmarks

COPY root/ /
ENTRYPOINT ["/run.sh"]
