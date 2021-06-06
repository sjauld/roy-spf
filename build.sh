#!/bin/zsh

echo "Building sender.zip"
go build -v ./src/sender/.
zip sender.zip sender
rm sender

echo "Building tracker.zip"
go build -v ./src/tracker/.
zip tracker.zip tracker
rm tracker
