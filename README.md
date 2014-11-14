architecture-setup
================

This tool is used to install Bindle and all of its dependencies pertaining to the pancancer project. 
This will likely grow to include youxia and all other infrastructure used specifically by pancancer. 
The result is a host that can be used to create new SeqWare images with pancancer workflows pre-installed.

## Setup

This playbook relies upon bindle's install playbook. 

    git clone https://github.com/CloudBindle/Bindle.git playbooks/Bindle

## Running 
        
    ansible-playbook -i inventory site.yml
