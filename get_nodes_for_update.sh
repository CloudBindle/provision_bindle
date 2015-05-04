#!/bin/bash
WORKFLOW_VERSION=$1
USER_WORKFLOW_NAME=$2
# The default workflow name is for Sanger, but this can be overridden by passing some other string as the second argument,
# for example:
# get_nodes_for_update.sh 1.0-SNAPSHOT HelloWorld 
# will select nodes with the HelloWorld bundle, version 1.0-SNAPSHOT
WORKFLOW_NAME=Workflow_Bundle_SangerPancancerCgpCnIndelSnvStr

if [  ! -z $USER_WORKFLOW_NAME ] ; then
  WORKFLOW_NAME=Workflow_Bundle_$USER_WORKFLOW_NAME
fi

# Probably several ways to get a list of worker nodes, but maybe best to just ask vagrant directly.
# Get a list of everything that varant is managing (that's also in the Bindle directory)
# $NODES will be an array of directories of vagrant-managed workers.
LOG_FILE=$(basename $BASH_SOURCE).log
echo "[ Begin Log, "$(date)" ]">>$LOG_FILE
{
echo "Getting list of workers from Vagrant"

NODES=($(vagrant global-status | grep ".*running .*/Bindle/.*" | sed 's/.* \(\/home\/.*\/Bindle\/[^\/]*\).*/\1/g'))

if [ ${#NODES[@]} = 0 ] ; then
  echo "Vagrant is not aware of any running nodes. Exiting..."
  exit 1
fi


# Write an inventory file containing all nodes that need to be checked to see if they can be updated.
#echo "[master]" > candidate_nodes_for_update_inventory
n=1
echo -n "" > candidate_nodes_for_update_inventory
for node_dir in "${NODES[@]}"
do
  echo "[host_$n]" >> candidate_nodes_for_update_inventory
  MACHINE_NAME=$(basename $node_dir)
  NODE_INVENTORY=$(cat "$node_dir"/inventory | grep ansible_ssh_host)
  NODE_INVENTORY=$(echo $NODE_INVENTORY | sed 's/master /'$MACHINE_NAME' /g')
  echo -e $NODE_INVENTORY'\n' >> candidate_nodes_for_update_inventory
  n=$((n + 1))
done

# Need to first copy status check script template.
cp ~/architecture-setup/monitoring-bag/roles/client/templates/check-seqware-sanger-last-workflow-status.json.j2 ./check-seqware-sanger-last-workflow-status.sh
# replace the Ansible variable with a real value.
sed -i 's/{{ workflow_version }}/'$WORKFLOW_VERSION'/g' check-seqware-sanger-last-workflow-status.sh
# George's script always searches for workflows prefixed with "Workflow_Bundle_" but this line
# modifies the script to search for ANY workflow name.
sed -i 's/Workflow_Bundle_$workflow_version/'$WORKFLOW_NAME'/g' check-seqware-sanger-last-workflow-status.sh

# Tell ansible to run the status-check script for all machines in nodes_for_update_inventory.
NODES_TO_UPDATE=()
echo "Checking for workers that have completed their work..."
for ((i=1; i<=${#NODES[@]}; i++));
do
  echo "Checking node:"
  HOST_LINE=$(grep -A 1 -e "\[host_$i\]" ~/architecture-setup/candidate_nodes_for_update_inventory | sed 's/\[host_'$i'\]//g')
  echo $HOST_LINE
  export PYTHONUNBUFFERED=1
  ANSIBLE_RESULT=$(ansible host_$i -v -i ~/architecture-setup/candidate_nodes_for_update_inventory  -m script -a check-seqware-sanger-last-workflow-status.sh)
  ANSIBLE_STD_OUT=$(echo $ANSIBLE_RESULT |  sed 's/.*"stdout": "\([^"]*\)".*/\1/g')
  ANSIBLE_STD_ERR=$(echo $ANSIBLE_RESULT |  sed 's/.*"stderr": "\([^"]*\)".*/\1/g')
  if [[ "$ANSIBLE_STD_OUT" =~ .*The\ status\ of\ the\ last\ job\ is\ completed.* ]] ; then 
    echo "Worker has completed and will be added to the inventory for nodes that will be updated."
    NODES_TO_UPDATE+=("$HOST_LINE")
  else
    echo "Worker has not completed, message received by Ansible: $ANSIBLE_STD_OUT"
    if [ ! "$ANSIBLE_STD_ERR" = '' ] ; then 
      echo "Std Err: $ANSIBLE_STD_ERR"
    fi
  fi
  printf "\n";
done

if [ ${#NODES_TO_UPDATE[@]} -gt 0 ] ; then
  echo "[master]" > nodes_to_update_inventory
  for node_line in "${NODES_TO_UPDATE[@]}"
  do  
    echo $node_line >> nodes_to_update_inventory
  done
  # Now back up the old inventory file, and copy the new one in.
  DATE_STRING=$(date +"%Y%m%d_%H%M%S")
  [ -e ~/architecture-setup/pancancer-bag/workflow-update/inventory ] && cp ~/architecture-setup/pancancer-bag/workflow-update/inventory  ~/architecture-setup/pancancer-bag/workflow-update/inventory_${DATE_STRING}.bkup
  cp nodes_to_update_inventory ~/architecture-setup/pancancer-bag/workflow-update/inventory
fi
} | tee -a $LOG_FILE
# because the script executes inside "{...} | tee", we need to capture the exit code
# before writing the last line of th log file, and then return THAT exit code.
SCRIPT_EXIT_CODE=${PIPESTATUS[0]}
echo "[ End Log, "$(date)" ]">>$LOG_FILE
exit $SCRIPT_EXIT_CODE
