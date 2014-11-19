architecture-setup
================

This tool is used to install Bindle and all of its dependencies pertaining to the pancancer project. 
This will likely grow to include youxia and all other infrastructure used specifically by pancancer. 
The result is a host that can be used to create new SeqWare images with pancancer workflows pre-installed.

## Setup

This playbook relies upon bindle's install playbook. 

    sudo apt-get install git
    sudo apt-get install python-software-properties
    sudo add-apt-repository ppa:rquillo/ansible
    sudo apt-get update
    sudo apt-get install ansible
    git clone https://github.com/CloudBindle/Bindle.git playbooks/Bindle

## Running 

You will need to edit uour inventory. Replace the pem file and the ip address of the launcher host that you wish to create with your desired launcher host. Ansible will obviously require SSH, therefore make sure that port 22 is open to your desired launcher host. 
        
    ansible-playbook -i inventory site.yml
