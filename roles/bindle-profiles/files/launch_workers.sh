#! /bin/bash

WORKER_TYPE=${1,,}
WORKER_NAME=$2

# before launching workers, copy config from the shared volume
cp /opt/from_host/config/.bindle/* ~/.bindle/

# now that we have a config file, let's launch something!
cd ~/architecture-setup/Bindle
perl bin/launch_cluster.pl --config $WORKER_TYPE --custom-params $WORKER_NAME

# Execute the argument passed in from the Dockerfile
#${3-bash}

