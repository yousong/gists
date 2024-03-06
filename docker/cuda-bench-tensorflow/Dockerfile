FROM tensorflow/tensorflow:2.15.0-gpu

ENV \
	TF_FORCE_GPU_ALLOW_GROWTH=true \
	TF_CPP_MIN_LOG_LEVEL=2 \
	PYTHONUNBUFFERED=1

RUN set -ex \
	&& apt-get update \
	&& apt-get install -y git \
	&& cd / \
	&& git clone --single-branch --branch=master --depth=1 https://github.com/tensorflow/benchmarks.git
WORKDIR /benchmarks/scripts/tf_cnn_benchmarks

COPY root/ /
ENTRYPOINT ["/run.sh"]
