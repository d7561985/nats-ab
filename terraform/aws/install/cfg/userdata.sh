#!/bin/bash
VERSION=v2.7.2
CLI_VERSION=0.0.34
TOP_VERSION=0.5.2

curl -L https://github.com/nats-io/nats-server/releases/download/$VERSION/nats-server-$VERSION-linux-amd64.zip -o nats-server.zip
unzip nats-server.zip -d nats-server
sudo  cp nats-server/nats-server-$VERSION-linux-amd64/nats-server /usr/bin

curl -L https://github.com/nats-io/natscli/releases/download/v$CLI_VERSION/nats-$CLI_VERSION-linux-amd64.zip -o natscli.zip
unzip natscli.zip -d natscli
sudo  cp natscli/nats-${CLI_VERSION}-linux-amd64/nats /usr/bin

curl -L https://github.com/nats-io/nats-top/releases/download/v${TOP_VERSION}/nats-top_${TOP_VERSION}_linux_amd64.tar.gz -o top.tar.gz
tar -xvf top.tar.gz
sudo cp nats-top /usr/bin