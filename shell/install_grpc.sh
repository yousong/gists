#!/usr/bin/env bash

pb_ver=3.6.0
pb_zip=protoc-$pb_ver-linux-x86_64.zip
pb_zip_url=https://github.com/google/protobuf/releases/download/v$pb_ver/$pb_zip
pb_zip_pth="/tmp/$pb_zip"

# https://grpc.io/docs/quickstart/go.html
install_grpc_go() {
	go get -u google.golang.org/grpc # a mirror is at https://github.com/grpc/gprc-go
	go get -u github.com/golang/protobuf/protoc-gen-go
	wget --no-check-certificate -c -O "$pb_zip_pth"  "$pb_zip_url"
	(
		cd $HOME/.usr/
		unzip "$pb_zip_pth"
	)

	# cd $GOPATH/src/google.golang.org/grpc/examples/helloworld
	# go run greeter_server/main.go
	# go run greeter_client/main.go
	# protoc -I helloworld helloworld/helloworld.proto --go_out=plugins=grpc:helloworld
}

# https://grpc.io/docs/quickstart/python.html
install_grpc_py() {
	# requires pip 9.0.1 or higher
	# pip install --upgrade pip
	pip install grpcio
	pip install grpcio-tools googleapis-common-protos

	# git clone -b v1.13.x https://github.com/grpc/grpc
	# cd grpc/examples/python/helloworld
	# python greeter_server.py
	# python greeter_client.py
	# python -m grpc_tools.protoc -I../../protos --python_out=. --grpc_python_out=. ../../protos/helloworld.proto
}

install_grpc_"$1"
