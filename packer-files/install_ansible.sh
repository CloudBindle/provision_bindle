#! /bin/bash

#sudo apt-get -y install git
#sudo add-apt-repository --yes ppa:rquillo/ansible
sudo add-apt-repository --yes ppa:ansible/ansible
#sudo add-apt-repository --yes ppa:git-core/ppa
sudo apt-get update
sudo apt-get -y install python-software-properties

# Make sure we get Ansible 1.9.*
ANSIBLE_VERSION=$(apt-cache showpkg ansible | grep "^1\.9[^[:space:]]*" | sed 's/^\(1\.9[^ ]*\) .*$/\1/' | tail -1)
echo "Using Ansible version: $ANSIBLE_VERSION"
[ -z "$ANSIBLE_VERSION" ] && echo "Could not detect Ansible 1.9.*, available versions are: " && apt-cache showpkg ansible && exit
sudo apt-get -y install ansible=$ANSIBLE_VERSION

