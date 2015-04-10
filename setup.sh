#!/bin/bash

sudo apt-get -y install git
sudo add-apt-repository --yes ppa:rquillo/ansible
sudo apt-get update
sudo apt-get -y install python-software-properties
sudo apt-get -y install ansible
sudo apt-get -y install build-essential
sudo apt-get -y install libxslt1-dev
sudo apt-get -y install libxml2-dev
sudo apt-get -y install zlib1g-dev
# Initialize and update submodules, but let the main architecture-setup playbook check out the right version.
git submodule init
git submodule update

