#!/bin/bash

if [ "$TRAVIS_OS_NAME" = "osx" ]; then
  brew update
  brew outdated xctool || brew upgrade xctool
  (xcrun simctl list)
  wget http://travisci.rubymotion.com/ -O RubyMotion-TravisCI.pkg
  sudo installer -pkg RubyMotion-TravisCI.pkg -target /
  cp -r /usr/lib/swift/*.dylib /Applications/Xcode.app/Contents/Frameworks/
  touch /Applications/Xcode.app/Contents/Frameworks/.swift-5-staged
  sudo mkdir -p ~/Library/RubyMotion/build
  sudo chown -R travis ~/Library/RubyMotion
  eval "sudo motion activate $RUBYMOTION_LICENSE"
  sudo motion update
  (motion --version)
  (ruby --version)
  motion repo
fi