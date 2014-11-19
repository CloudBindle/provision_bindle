#!/bin/bash

sudo apt-get -y install git
sudo apt-get -y install python-software-properties
sudo add-apt-repository ppa:rquillo/ansible
sudo apt-get update
sudo apt-get -y install ansible
git clone https://github.com/CloudBindle/Bindle.git playbooks/Bindle

