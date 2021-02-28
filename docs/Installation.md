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
* A Bourne-compatible shell for installation (e.g. `bash` or `zsh`) <sup>[3](#3)</sup>

## Alternative Installs

### Linux or Windows 10 Subsystem for Linux

Check out [the Homebrew on Linux installation documentation](Homebrew-on-Linux.md).

### Untar anywhere

Just extract (or `git clone`) Homebrew wherever you want. Just avoid:

* Directories with names that contain spaces. Homebrew itself can handle spaces, but many build scripts cannot.
* `/tmp` subdirectories because Homebrew gets upset.
* `/sw` and `/opt/local` because build scripts get confused when Homebrew is there instead of Fink or MacPorts, respectively.

However do yourself a favour and install to `/usr/local` on macOS Intel, `/opt/homebrew` on macOS ARM,
and `/home/linuxbrew/.linuxbrew` on Linux. Some things may
not build when installed elsewhere. One of the reasons Homebrew just
works relative to the competition is **because** we recommend installing
here. *Pick another prefix at your peril!*

```sh
mkdir homebrew && curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C homebrew
```

### Multiple installations

Create a Homebrew installation wherever you extract the tarball. Whichever `brew` command is called is where the packages will be installed. You can use this as you see fit, e.g. a system set of libs in `/usr/local` and tweaked formulae for development in `~/homebrew`.

## Uninstallation

Uninstallation is documented in the [FAQ](FAQ.md).

<a name="1"><sup>1</sup></a> For 32-bit or PPC support see
[Tigerbrew](https://github.com/mistydemeo/tigerbrew).

<a name="2"><sup>2</sup></a> 10.14 or higher is recommended. 10.9–10.13 are
supported on a best-effort basis. For 10.4-10.6 see
[Tigerbrew](https://github.com/mistydemeo/tigerbrew).

<a name="3"><sup>4</sup></a> The one-liner installation method found on
[brew.sh](https://brew.sh) requires a Bourne-compatible shell (e.g. bash or
zsh). Notably, fish, tcsh and csh will not work.
