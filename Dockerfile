# Based on Ubuntu 14
FROM ubuntu:14.04

MAINTAINER Solomon Shorser <solomon.shorser@oicr.on.ca>
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
RUN git clone https://github.com/ICGC-TCGA-PanCancer/architecture-setup.git && \
    cd architecture-setup && \
    git checkout 2.0.0 && \
    git clone https://github.com/CloudBindle/Bindle.git playbooks/Bindle && \
    cd playbooks/Bindle && \
    git checkout 2.0.0 

WORKDIR /home/ubuntu/architecture-setup
# This is so we can see the ansible output as the playbook is running, rather than wait until after it completes.
ENV PYTHONUNBUFFERED 1
RUN ansible-playbook -i inventory site.yml
    
