#!/bin/bash
ARCHITECTURE_SETUP_VERSION=$1
WORKFLOW_VERSION=$(cat roles/bindle-profiles/vars/main.yml | grep workflow_version | sed -e 's/workflow_version: "\([^"]*\)"/\1/g' )
echo "Upgrading to architecture-setup $ARCHITECTURE_SETUP_VERSION, with workflow version: $WORKFLOW_VERSION"
if [ -n "$WORKFLOW_VERSION" ] ; then
  bash ./upgrade_architecture_setup.sh -v $ARCHITECTURE_SETUP_VERSION
  [[ $? -ne 0 ]] && exit $?
  bash ./get_nodes_for_update.sh $WORKFLOW_VERSION
  [[ $? -ne 0 ]] && exit $?
  bash ./upgrade_worker_nodes.sh $WORKFLOW_VERSION
  [[ $? -ne 0 ]] && exit $?
else
  echo "You must provide the version of architecture-setup that you wish to upgrade to:" 
  echo "  upgrade_launcher_and_workers.sh 1.0.5"
fi
