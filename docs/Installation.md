# Installation

Instructions for a supported install of Homebrew are on the [homepage](https://brew.sh).

This script installs Homebrew to its preferred prefix (`/usr/local`
for macOS Intel, `/opt/homebrew` for Apple Silicon) so that
[you don’t need sudo](FAQ.md#why-does-homebrew-say-sudo-is-bad) when you
`brew install`. It is a careful script; it can be run even if you have stuff
installed in `/usr/local` already. It tells you exactly what it will do before
it does it too. You have to confirm everything it will do before it starts.

## macOS Requirements

* A 64-bit Intel CPU or Apple Silicon CPU <sup>[1](#1)</sup>
* macOS Mojave (10.14) (or higher) <sup>[2](#2)</sup>
* Command Line Tools (CLT) for Xcode: `xcode-select --install`,
  [developer.apple.com/downloads](https://developer.apple.com/downloads) or
  [Xcode](https://itunes.apple.com/us/app/xcode/id497799835) <sup>[3](#3)</sup>
* A Bourne-compatible shell for installation (e.g. `bash` or `zsh`) <sup>[4](#4)</sup>

## Git Remote Mirroring

You can set `HOMEBREW_BREW_GIT_REMOTE` and/or `HOMEBREW_CORE_GIT_REMOTE` in your shell environment to use geolocalized Git mirrors to speed up Homebrew's installation with this script and, after installation, `brew update`.

```bash
export HOMEBREW_BREW_GIT_REMOTE="..."  # put your Git mirror of Homebrew/brew here
export HOMEBREW_CORE_GIT_REMOTE="..."  # put your Git mirror of Homebrew/homebrew-core here
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
```

The default Git remote will be used if the corresponding environment variable is unset.

##
