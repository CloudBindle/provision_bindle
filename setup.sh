#!/bin/bash

sudo apt-get -y install git
sudo add-apt-repository --yes ppa:rquillo/ansible
sudo add-apt-repository --yes ppa:ansible/ansible
sudo apt-get update
sudo apt-get -y install python-software-properties
sudo apt-get -y install ansible
sudo apt-get -y install build-essential
sudo apt-get -y install libxslt1-dev
sudo apt-get -y install libxml2-dev
sudo apt-get -y install zlib1g-dev
[[ -d ~/.ssh ]] || mkdir ~/.ssh
touch ~/.ssh/gnostest.pem
touch ~/.ssh/gnos.pem
git clone https://github.com/ICGC-TCGA-PanCancer/architecture-setup.git
cd architecture-setup 
git clone https://github.com/CloudBindle/Bindle.git playbooks/Bindle
cd playbooks/Bindle
git checkout release/2.0.0
cd ../..
ansible-playbook -i inventory site.yml
