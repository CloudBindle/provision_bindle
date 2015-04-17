FROM ubuntu:14.04
RUN apt-get install -y software-properties-common && \
    apt-get update && \
    add-apt-repository "deb http://ca.archive.ubuntu.com/ubuntu precise main" && \
    add-apt-repository --yes ppa:rquillo/ansible && \
    apt-get install -y mcrypt git ansible vim curl build-essential libxslt1-dev libxml2-dev zlib1g-dev

# Create ubuntu user and group, make the account passwordless
RUN groupadd ubuntu && \
    useradd ubuntu -m -g ubuntu && \
    usermod -a -G sudo,ubuntu ubuntu && \
    passwd -d ubuntu

USER ubuntu
ENV HOME /home/ubuntu
ENV USER ubuntu
WORKDIR /home/ubuntu

ENV PYTHONUNBUFFERED 1
RUN curl -L https://raw.githubusercontent.com/ICGC-TCGA-PanCancer/architecture-setup/develop/setup.sh | bash

