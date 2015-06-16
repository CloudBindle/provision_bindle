#! /bin/bash

WORKER_TYPE=$1
WORKER_NAME=$2

cp /opt/from_host/config/${WORKER_TYPE}.cfg ~/.bindle/${WORKER_TYPE}.cfg
cd ~/architecture-setup/Bindle
perl bin/launch_cluster.pl --config $WORKER_TYPE --custom-params $WORKER_NAME

#${3-bash}
exit

