#!/bin/bash -eu

open https://www.iterm2.com/downloads.html
open https://www.alfredapp.com/
open http://www.oracle.com/technetwork/java/javase/downloads/index.html
open https://docs.docker.com/docker-for-mac/
open https://www.tug.org/mactex/
open https://atom.io/
open https://code.visualstudio.com/
open https://1password.com/

# Evernote
open https://itunes.apple.com/jp/app/evernote-stay-organized/id406056744?l=en&mt=12
# Slack
open https://itunes.apple.com/jp/app/slack/id803453959?l=en&mt=12
# NightOwl
open https://itunes.apple.com/jp/app/night-owl/id428834068?l=en&mt=12


# Google Cloud SDK
wget -O $HOME/google-cloud-sdk.tar.gz https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-159.0.0-darwin-x86_64.tar.gz
tar xvzf $HOME/google-cloud-sdk.tar.gz -C $HOME
$HOME/google-cloud-sdk/install.sh --quiet
gcloud components update
gcloud install beta

# node.js
curl -L git.io/nodebrew | perl - setup
nodebrew install-binary v8
nodebrew use v8
npm install -g typescript typescript-formatter yarn @angular/cli

# rustup
curl https://sh.rustup.rs -sSf | sh -s -- -y

# emscripten
