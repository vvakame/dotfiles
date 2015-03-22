git submodule init
git submodule update

./ln.sh
./brew.sh

# Macの設定
defaults write com.apple.dock autohide -bool Yes; killall Dock

# ssh公開鍵をいろいろなところに配る
# JDK 入れる
# brew cask alfred link

# iterm2でGeneral -> Preferences で Dropboxのsettingsフォルダのあそこ指定する

# sudo vi /etc/shells に /usr/local/bin/zsh 追加して chsh -s /usr/local/bin/zsh

# nodebrew と rbenv 設定
# rbenv install 1.9.3-p547
# rbenv install 2.2.1
# rbenv global 2.2.1

# Re:VIEW環境構築
# rbenv rehash
# gem install review
# rbenv rehash

# QuickRes
# gumroad
