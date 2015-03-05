#!/bin/bash
# set -e
LOG_FILE=$(basename $BASH_SOURCE).log
echo "[ Begin Log, "$(date)" ]">>$LOG_FILE
{
WORKFLOW_VERSION=$1
if [ -n "$WORKFLOW_VERSION" ] ; then
  cd ~/architecture2/pancancer-bag
  if [ ! -d workflow-update/roles/update_workflow/files ] ; then
    mkdir workflow-update/roles/update_workflow/files
  fi
  DOWNLOAD_PATH=workflow-update/roles/update_workflow/files
  WORKFLOW_FILE=Workflow_Bundle_SangerPancancerCgpCnIndelSnvStr_"$WORKFLOW_VERSION"_SeqWare_1.1.0-alpha.5.zip
  TARGET_FILE=${DOWNLOAD_PATH}/${WORKFLOW_FILE}
  if [ ! -e $TARGET_FILE ] ; then
    echo "File $TARGET_FILE is not available locally. Downloading workflow now..."
    wget -O $TARGET_FILE https://s3.amazonaws.com/oicr.workflow.bundles/released-bundles/$WORKFLOW_FILE
  else
    echo "Requested file $WORKFLOW_FILE already exists in $DOWNLOAD_PATH"
  fi
  cd workflow-update
  export PYTHONUNBUFFERED=1
  ansible-playbook -i inventory site.yml
  cd ~/architecture2/Bindle
  perl bin/generate_master_inventory_file_for_ansible.pl > inventory_for_cluster_json_generator
  echo "Creating a new cluster.json file"
  cd ~/architecture2/workflow-decider
  perl bin/create_cluster_json.pl --specific-workflow-version $WORKFLOW_VERSION --inventory-file ~/architecture2/Bindle/inventory_for_cluster_json_generator --workflow-name SangerPancancerCgpCnIndelSnvStr > cluster_SangerPancancerCgpCnIndelSnvStr_${WORKFLOW_VERSION}.json
else
  echo "You need to specify a workflow verion. Example:"
  echo "  upgrade_worker_nodes.sh 1.0.5"
fi
} | tee -a $LOG_FILE
echo "[ End Log, "$(date)" ]">>$LOG_FILE
