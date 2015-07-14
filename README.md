architecture-setup
==================

architecture-setup is used by pancancer\_launcher to create a docker image that can be used to create and manage a fleet of VMs that will run SeqWare workflows.

##Submodules of architecture-setup:

* [monitoring-bag](https://github.com/ICGC-TCGA-PanCancer/monitoring-bag.git) - This is used to set up monitoring components on the main controller of the fleet, and also on the worker nodes.
* [central-decider-client](https://github.com/ICGC-TCGA-PanCancer/central-decider-client) - This is used on the main controller node to get INI files for the workers.
* [container-host-bag](https://github.com/ICGC-TCGA-PanCancer/container-host-bag) - This is used to set up the worker nodes.

This project contains ansible roles that are used to create the pancancer\_launcher container.

 - bindle-profiles - This is a basic bootstrap role that ensures that the submodules are checked out correctly, and then places some of the pancancer\_launcher scripts on their correct paths.
 - arch3_master - This sets up Architecture3 components inside the pancancer\_launcher container
 - java - This is a role that is used to install and set up Java inside the pancancer\_launcher.

The scripts and files that you will most likely be using or modifying are:

 - **start\_launcher\_container.sh** - This is used to start an instance of pancancer\_launcher. The script is called like this:

        bash start_launcher_container.sh ~/.ssh/my_key.pem 3.1.0 AWS true

  The arguments are:
  1. The path to a PEM key
  2. The version of pancancer\_launcher to use.
  3. The environment ("AWS" or "OPENSTACK") that the launcher is running in.
  4. Test mode (if true, workers will be launched automatically when the container completes its startup).

  It is also possible to call this in a simpler way by omitting the last two arguments. They will take on the assumed values "AWS" and "false":
  
      bash start_launcher_container.sh ~/.ssh/my_key.pem 3.1.0

 - **roles/bindle-profiles/files/bashrc** - This is a bashrc file that is set up for the ubuntu use inside the pancancer\_launcher container. It is based on the Ubuntu 14.04 default bashrc file, but has a custom prompt containing the pancancer\_launcher version number.
 - **roles/bindle-profiles/files/launch\_workers.sh** - This is a file that can be used to launcher worker nodes automatically from the pancancer\_launcher container. It is primarily intended to be used from Jenkins or other build/test tools so that a complete end-to-end test can be executed without manual intervention. It is activated by passing the value "true" (to indicate that you want to run in test mode) as the last argument to `start_launcher_container.sh`.
 - **start\_services\_in\_container.sh** - This script runs when the container starts up. It is responsible for starting up the services inside the container: rabbitMQ, redis, postgres, sensu, and uchiwa. It also sets up the rabbitMQ users and vhosts (if they are not set up already), and sets the `PUBLIC_IP_ADDRESS` and `SENSU_SERVER_IP_ADDRESS` variables that are needed inside the container.
