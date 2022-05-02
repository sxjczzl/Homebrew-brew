FROM debian:stretch
ARG DEBIAN_FRONTEND=noninteractive

# hadolint ignore=DL3008
RUN apt-get update \
   && apt-get install -y build-essential procps curl file git

RUN useradd -m -s /bin/bash linuxbrew
RUN echo 'linuxbrew ALL=(ALL) NOPASSWD:ALL' >>/etc/sudoers
RUN su - linuxbrew -c 'mkdir ~/.linuxbrew'

RUN /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

RUN chown -R linuxbrew /home/linuxbrew/.linuxbrew

RUN echo "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" >> /home/linuxbrew/.bashrc
