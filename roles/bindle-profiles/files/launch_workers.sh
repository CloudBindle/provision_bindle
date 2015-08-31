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

# Each command is preceeded by a sleep because it seems that the database might not have finished starting by the time these commands are executed.

# run the Generator
sleep 60
echo "Running Generator"
Generator --workflow-name HelloWorld --workflow-version 1.0-SNAPSHOT --workflow-path /workflows/Workflow_Bundle_HelloWorld_1.0-SNAPSHOT_SeqWare_1.1.0 --config ~/arch3/config/masterConfig.ini --total-jobs 1

#Run the Coordinator
sleep 60
echo "Running Coordinator"
Coordinator --config config/masterConfig.ini
cat coordinator.out

#Run the Provisioner
sleep 60
echo "Running Provisioner"
Provisioner --config config/masterConfig.ini
cat provisioner.out

#Worker should be reaped automatically if it completes successfuly
