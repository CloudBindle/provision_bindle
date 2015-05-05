#! /bin/bash

# There are few ways to install architecture-setup inside the container:
# 1) From the setup.sh script inside the container
# 2) Checking out a specific version of the repo inside the container
# 3) Checkout out the repo on the build machine and copying local files into the docker container

LAUNCHER_VERSION=$1
REF=$2
BUILD_DATE=$(date +"%y-%m-%d %H:%M:%S")

read -r -d '' COMMON<<'STARTBLOCK'
# Based on Ubuntu 14
FROM ubuntu:14.04
MAINTAINER Solomon Shorser <solomon.shorser@oicr.on.ca>
LABEL architecture-setup=ARCH_SETUP_VERSION build-date=IMAGE_BUILD_DATE

# some packages needed by the other bags needed packages in "precise" but not in "trusty". Specifically, libdb4.8 was needed.
RUN apt-get install -y software-properties-common && \
    add-apt-repository "deb http://ca.archive.ubuntu.com/ubuntu precise main" && \
    add-apt-repository --yes ppa:rquillo/ansible && \
    add-apt-repository --yes ppa:ansible/ansible && \
    apt-get update

RUN apt-get install -y python-apt mcrypt git ansible vim curl build-essential libxslt1-dev libxml2-dev zlib1g-dev

# Create ubuntu user and group, make the account passwordless
RUN groupadd ubuntu && \
    useradd ubuntu -m -g ubuntu && \
    usermod -a -G sudo,ubuntu ubuntu && \
    passwd -d ubuntu

USER ubuntu
ENV HOME /home/ubuntu
ENV USER ubuntu
WORKDIR /home/ubuntu
# Running the setup script directly makes for a simple Dockerfile, but less control of how the image is built.
# Also, the setup script tries to install some of the same packages we installed above.
# RUN curl -L https://raw.githubusercontent.com/ICGC-TCGA-PanCancer/architecture-setup/develop/setup.sh | bash
RUN mkdir ~/.ssh && touch ~/.ssh/gnostest.pem && \
    touch ~/.ssh/gnos.pem

ENV PYTHONUNBUFFERED 1
STARTBLOCK

read -r -d '' BUILD_FROM_SCRIPT <<'SCRIPTBLOCK'
RUN curl -L https://raw.githubusercontent.com/ICGC-TCGA-PanCancer/architecture-setup/develop/setup.sh | bash
SCRIPTBLOCK

read -r -d '' BUILD_FROM_CHECKOUT <<'CHECKOUTBLOCK'
RUN git clone https://github.com/ICGC-TCGA-PanCancer/architecture-setup.git && \
    cd architecture-setup && \
    git checkout GIT_REF && \
    git submodule init && git submodule update && \ 
    cd youxia/youxia-setup &&
    ansible-playbook -i inventory site.yml
CHECKOUTBLOCK

read -r -d '' BUILD_FROM_LOCAL_SOURCE <<'LOCALSRCBLOCK'
# This assumes you will run the docker build command from your local architecture-setup directory
ADD . /home/ubuntu/architecture-setup
WORKDIR /home/ubuntu/architecture-setup
RUN bash setup.sh
LOCALSRCBLOCK

read -r -d '' END <<'ENDBLOCK'
WORKDIR /home/ubuntu/architecture-setup
ENDBLOCK

COMMON=$(echo "$COMMON" | sed s/'ARCH_SETUP_VERSION'/$LAUNCHER_VERSION/g )
COMMON=$(echo "$COMMON" | sed s/'IMAGE_BUILD_DATE'/"$BUILD_DATE"/g )

DOCKERFILE="$COMMON\n$BUILD_FROM_SCRIPT\n$END"
echo -e "$DOCKERFILE" > Dockerfile.script.tmp

DOCKERFILE="$COMMON\n$BUILD_FROM_CHECKOUT\n$END"
DOCKERFILE=${DOCKERFILE//GIT_REF/"$REF"}
echo -e "$DOCKERFILE" > Dockerfile.checkoutincontainer.tmp

DOCKERFILE="$COMMON\n$BUILD_FROM_LOCAL_SOURCE\n$END"
echo -e "$DOCKERFILE" > Dockerfile.localsrc.tmp

#docker build -t seqware/launcher --rm=true --no-cache=true .

#docker build -t seqware/launcher .
