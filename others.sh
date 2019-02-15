#!/bin/bash -eu

open https://www.iterm2.com/downloads.html
open https://www.alfredapp.com/
open http://www.oracle.com/technetwork/java/javase/downloads/index.html
open https://hub.docker.com/editions/community/docker-ce-desktop-mac
open https://www.tug.org/mactex/
open https://atom.io/
open https://code.visualstudio.com/
open https://www.sketchapp.com/
open https://1password.com/
open https://discordapp.com/
open https://store.steampowered.com/about/

# Xcode
open https://itunes.apple.com/jp/app/xcode/id497799835?l=en&mt=12
# Slack
open https://itunes.apple.com/jp/app/slack/id803453959?l=en&mt=12
# NightOwl
open https://itunes.apple.com/jp/app/night-owl/id428834068?l=en&mt=12
# Affinity Designer
open https://itunes.apple.com/jp/app/affinity-designer/id824171161?l=en&mt=12
# Skitch
open https://itunes.apple.com/jp/app/skitch-snap-mark-up-share/id425955336?l=en&mt=12

# Google Cloud SDK
wget -O $HOME/google-cloud-sdk.tar.gz https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-234.0.0-darwin-x86_64.tar.gz
tar xvzf $HOME/google-cloud-sdk.tar.gz -C $HOME
$HOME/google-cloud-sdk/install.sh --quiet
gcloud components update
gcloud components install beta -q

# node.js
curl -L git.io/nodebrew | perl - setup
nodebrew install-binary v11
nodebrew use v11
npm install -g typescript typescript-formatter yarn @angular/cli
npm install -g typescript typescript-formatter yarn firebase-tools live-server @angular/cli

# rustup
curl https://sh.rustup.rs -sSf | sh -s -- -y

# emscripten
