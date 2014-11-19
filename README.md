architecture-setup
================

This tool is used to install Bindle and all of its dependencies pertaining to the pancancer project. 
This will likely grow to include youxia and all other infrastructure used specifically by pancancer. 
The result is a host that can be used to create new SeqWare images with pancancer workflows pre-installed.

###Sets up the following on the desired node(s)

* [Bindle](https://github.com/CloudBindle/Bindle)
* [Seqware-bag](https://github.com/SeqWare/seqware-bag.git)
* [Pancancer-bag](https://github.com/ICGC-TCGA-PanCancer/pancancer-bag.git)
* [Monitoring-bag](https://github.com/ICGC-TCGA-PanCancer/monitoring-bag.git)

## Setup

This playbook relies upon bindle's install playbook. 

    sudo apt-get install git
    git clone https://github.com/ICGC-TCGA-PanCancer/architecture-setup.git
    cd architecture-setup 
    bash setup.sh
    
You will also need to get a confidential pem key for GNOS upload/download from your GNOS admin or a fellow cloud shepard. Please copy it to /home/ubuntu/.ssh/gnostest.pem 

## Running 

If you wish to setup the host your are currently on as a launcher host, skip directly to the command below. 

If you wish to setup some other host, you will need to edit uour inventory. Replace the pem file and the ip address of the launcher host that you wish to create with your desired launcher host. Ansible will obviously require SSH, therefore make sure that port 22 is open to your desired launcher host. 
        
    ansible-playbook -i inventory site.yml

Navigate to ~/architecture2 and follow the rest of the pancancer-info instructions on how to setup and use bindle
