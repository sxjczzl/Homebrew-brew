#!/bin/bash

brew install hello
brew test hello
brew uninstall hello
brew install -s hello
brew test hello
