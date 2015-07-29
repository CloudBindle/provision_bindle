#! /bin/bash

WORKER_TYPE=${1,,}

echo "Launching worker of type: $WORKER_TYPE"

# before launching workers, try to copy from the shared volume

cp /opt/from_host/config/youxia_config ~/.youxia/config
cp /opt/from_host/config/params.json ~/params.json
cp /opt/from_host/config/masterConfig.ini ~/arch3/config/masterConfig.ini

# now that we have config files, let's launch something!

cd ~/arch3/
OS_FLAG=""
if [ "$WORKER_TYPE" == "openstack" ] ; then
  OS_FLAG=" --openstack"
fi

# Deploying a new worker can also cause them to self-test installed workflows.
#java -cp pancancer.jar io.cloudbindle.youxia.deployer.Deployer --ansible-playbook ~/architecture-setup/container-host-bag/install.yml --max-spot-price 1 --batch-size 1 --total-nodes-num 1 -e ~/params.json $OS_FLAG

# TODO: start up a job queue and send >= 1 job to the new worker.

# Execute the argument passed in from the Dockerfile
#${3-bash}

#Now clean up the nodes we created.
# java -cp pancancer.jar io.cloudbindle.youxia.reaper.Reaper --kill-limit 0 $OS_FLAG

# run the Generator
Generator --workflow-name HelloWorld --workflow-version 1.0-SNAPSHOT --workflow-path /workflows/Workflow_Bundle_HelloWorld_1.0-SNAPSHOT_SeqWare_1.1.0 --config ~/arch3/config/masterConfig.ini --total-jobs 1

#Run the Coordinator
Coordinator --config config/masterConfig.ini $OS_FLAG

#Run the Provisioner
Provisioner --config config/masterConfig.ini $OS_FLAG

#Worker should be reaped automatically if it completes successfuly
