#!/bin/zsh

echo "Building sender.zip"
GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o bootstrap ./src/sender/.
zip sender.zip bootstrap
rm bootstrap

echo "Building tracker.zip"
GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o bootstrap ./src/tracker/.
zip tracker.zip bootstrap
rm bootstrap
