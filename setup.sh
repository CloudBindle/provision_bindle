#!/bin/bash

sudo apt-get -y install git
sudo apt-get -y install python-software-properties
sudo add-apt-repository --yes ppa:rquillo/ansible
sudo apt-get update
sudo apt-get -y install ansible
git clone https://github.com/CloudBindle/Bindle.git playbooks/Bindle
cd playbooks/Bindle
git checkout 2.0-alpha.2
cd ../..

