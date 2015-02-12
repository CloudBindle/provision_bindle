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
    
!!! IMPORTANT !!!    
You will also need to get a confidential pem key for GNOS upload/download from your GNOS admin or a fellow cloud shepard. Please copy it to /home/ubuntu/.ssh/gnostest.pem before running the next step, or otherwise the Ansible playbook will fail to run completely leaving the system in a half-broken state.

## Running 

If you wish to setup the host your are currently on as a launcher host, skip directly to the command below. 

If you wish to setup some other host, you will need to edit your inventory. Replace the pem file and the ip address of the launcher host that you wish to create with your desired launcher host. Ansible will obviously require SSH, therefore make sure that port 22 is open to your desired launcher host.
        
    ansible-playbook -i inventory site.yml

Navigate to ~/architecture2 and follow the rest of the pancancer-info instructions on how to setup and use bindle

## Upgrading to a new version
(Placeholder document for usage of `upgrade_architecture_setup.sh`)

## Creating a new release

It is possible to create a new release of architecture-setup from here using the script `create_release.sh`. Please ensure that you have bash 4.* to execute this script. You will need to install the additional package `jq`:

    sudo apt-get install jq
    
You wil also need a github authentication token. Detailed instructions can be found [here](https://help.github.com/articles/creating-an-access-token-for-command-line-use/). The token should be saved in a file named `github.token`. You will need to ensure that your github account has permission to create releases and check in files on the relevant projects or this script may fail.

Creating a new release involves examining projects that architecture-setup depends on and if there have been any commits since the last release of architecture-setup, the dependencies will be updated with a new release and the `vars/main.yml` file will be updated to refer to these new releases and checked in. A new release of architecture-setup will also be created.

Executing the script is done like this:

    bash create_release.sh -n <RELEASE_NAME> [-t][-h]
    
`-n <RELEASE_NAME>` is required. This will be used for the tag name for all projects that get updated in this release.

`-t` is used to execute the script in test mode. When executed in test mode, no releases are created and no files are committed.

`-h` will print help text.
