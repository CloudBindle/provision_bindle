#!/bin/bash
WORKFLOW_VERSION=$1
if [ -n "$WORKFLOW_VERSION" ] ; then
  bash ./upgrade_architecture_setup.sh -v $WORKFLOW_VERSION
  bash ./get_nodes_for_update.sh $WORKFLOW_VERSION Workflow_Bundle_SangerPancancerCgpCnIndelSnvStr
  bash ./upgrade_worker_nodes.sh $WORKFLOW_VERSION
else
  echo "You must provide a workflow verison number. Example" 
  echo "  upgrade_launcher_and_workers.sh 1.0.5"
fi
