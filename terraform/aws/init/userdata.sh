#!/bin/bash
curl -L https://github.com/nats-io/nats-server/releases/download/v2.7.2/nats-server-v2.7.2-linux-amd64.zip -o nats-server.zip
unzip nats-server.zip -d nats-server
cp nats-server/nats-server-v2.7.2-linux-amd64/nats-server /usr/bin

curl -L https://github.com/nats-io/natscli/releases/download/v0.0.29/nats-0.0.29-linux-amd64.zip -o natscli.zip
unzip natscli.zip -d natscli
cp natscli/nats-0.0.29-linux-amd64/nats /usr/bin

curl -L https://github.com/nats-io/nats-top/releases/download/v0.4.0/nats-top_0.4.0_linux_amd64.tar.gz -o top.tar.gz
tar -xvf top.tar.gz
cp nats-top /usr/bin