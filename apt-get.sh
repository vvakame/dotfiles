#!/bin/bash -eu

sudo apt-get update
# for h2o
sudo apt-get install -y g++ openssl pkg-config zlib1g-dev libuv-dev

sudo chmod +x /usr/share/doc/git/contrib/diff-highlight/diff-highlight

