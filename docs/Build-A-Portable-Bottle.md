# Building A Portabe Bottle for Linux

## Introduction

The bottles for `binutils`, `patchelf` and `zlib` are special. Because they are installed before `glibc`, they must be able to run on host systems using an older version of `glibc`. Linuxbrew supports host systems with `glibc` 2.13 and newer. We use Debian 7 (wheezy) with glibc 2.13 to build portable bottles.

## Here are the instructions to build and upload the bottle

```sh
docker pull debian/eol:wheezy
docker run -it --name=linuxbrew-wheezy debian/eol:wheezy
```

# Once in the running container, install the needed build dependencies
```sh
apt-get update
apt-get install -y bison flex texinfo gcc g++ make curl sudo git-core
```

# Install brew
```sh
useradd -m -s /bin/bash linuxbrew
echo 'linuxbrew ALL=(ALL) NOPASSWD:ALL' >>/etc/sudoers
su -l linuxbrew

export PATH=/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:$PATH
export HOMEBREW_CURL_PATH=/usr/bin/curl
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_DEVELOPER=1
sh -c "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install.sh)"
```

# Setup git config to be able to pull your PR
```sh
git config --global user.email "you@example.com"
git config --global user.name "Your Name"

brew pull <PR_NUMBER>
```

# Prevent brew to install brewed curl and git

To force brew to use the system curl and git, we need to modify brew.sh
Edit HOMEBREW_MINIMUM_GIT_VERSION and HOMEBREW_MINIMUM_CURL_VERSION in ~/.linuxbrew/Homebrew/Library/Homebrew/brew.sh

```sh
sudo apt-get install nano
nano ~/.linuxbrew/Homebrew/Library/Homebrew/brew.sh
```

Change HOMEBREW_MINIMUM_GIT_VERSION to 1.6 and HOMEBREW_MINIMUM_CURL_VERSION to 7.25.0 for example.
Now that we are done, cleanup after us:

```sh
sudo apt-get remove nano libgpm2 libncursesw5
```

# Build the bottle
```sh
brew install --build-bottle binutils
brew bottle --json binutils
```

# Upload the bottle
```sh
export HOMEBREW_BINTRAY_USER=*** HOMEBREW_BINTRAY_KEY=***
version=$(brew list --versions binutils | sed 's/.* //')
/usr/bin/curl -u$HOMEBREW_BINTRAY_USER:$HOMEBREW_BINTRAY_KEY -T binutils--$version.x86_64_linux.bottle.tar.gz "https://api.bintray.com/content/linuxbrew/bottles/binutils/$version/binutils-$version.x86_64_linux.bottle.tar.gz?publish=1" > curl.out
```

