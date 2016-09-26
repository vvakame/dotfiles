#!/bin/bash -eu

sudo apt-get update
sudo apt-get install -y git zsh

# for h2o
sudo apt-get install -y g++ cmake openssl pkg-config zlib1g-dev libuv-dev

sudo chmod +x /usr/share/doc/git/contrib/diff-highlight/diff-highlight

sudo apt-get install -y letsencrypt

