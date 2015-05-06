#!/bin/bash

sudo apt-get -y install git
sudo add-apt-repository --yes ppa:rquillo/ansible
sudo add-apt-repository --yes ppa:ansible/ansible
sudo add-apt-repository --yes ppa:git-core/ppa
sudo apt-get update
sudo apt-get -y install python-software-properties

# Make sure we get Ansible 1.9.*
ANSIBLE_VERSION=$(apt-cache showpkg ansible | grep "^1\.9[^[:space:]]*" | sed 's/^\(1\.9[^ ]*\) .*$/\1/' | tail -1)
echo "Using Ansible version: $ANSIBLE_VERSION"
[ -z "$ANSIBLE_VERSION" ] && echo "Could not detect Ansible 1.9.*, available versions are: " && apt-cache showpkg ansible && exit
sudo apt-get -y install ansible=$ANSIBLE_VERSION

sudo apt-get -y install build-essential
sudo apt-get -y install libxslt1-dev
sudo apt-get -y install libxml2-dev
sudo apt-get -y install zlib1g-dev
[[ -d ~/.ssh ]] || mkdir ~/.ssh
touch ~/.ssh/gnostest.pem
touch ~/.ssh/gnos.pem
git clone https://github.com/ICGC-TCGA-PanCancer/architecture-setup.git
cd architecture-setup 
# Initialize and update submodules, but let the main architecture-setup playbook check out the right version.
git submodule init
git submodule update
ansible-playbook -i inventory site.yml
# Some setup needed for youxia
#mkdir ~/.youxia && mkdir ~/.youxia/youxia_setup && mkdir ~/.youxia/youxia_setup/ssh
#cp ~/.ssh/*.pem ~/.youxia/youxia_setup/ssh/
#touch ~/.youxia/config
cd youxia/youxia-setup
ansible-playbook -i inventory site.yml
cd ../ansible-sensu
ansible-playbook -i inventory site.yml

