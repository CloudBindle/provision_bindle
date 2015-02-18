#!/bin/bash 
# This script will update files in pancancer-bag and monitoring-bag.
# TODO: Also update: workflow-decider: conf/sites/decider.oicr.ini ; conf/sites/decider.dkfz.32.ini ; conf/sites/decider.dkfz.64.ini ; cron/status.aws-oregon.cron ; cron/status.aws-ireland.cron
print_help()
{
  cat <<xxxHELPTEXT
This script updates references in monitoring-bag and pancancer-bag to a given
Sanger workflow version.
Currently, the files that get updated are: 
  monitoring-bag/contents/roles/client/vars/main.yml
  pancancer-bag/contents/workflow-update/roles/update_workflow/vars/main.yml

Usage:
  bash update_workflow_refs.sh -w 1.0.5

-w workflow_version   The version to update the bags to.
-t                    Test mode - script will execute but no commits will
                      happen.
-h                    Print this help text.
xxxHELPTEXT
exit
}

# Examine the header dump from curl in header.txt and exit the script if status is not 200 OK
process_curl_status()
{
  local raw_result="$1"
  local response_status=$(cat header.txt | grep Status | sed 's/[^0-9]*\([0-9]*\).*/\1/g')
  # 20* response codes (200 OK, 201 CREATED, etc...) mean some kind of succes, we'll treat everything
  # else as an error and print the message from the API. 
  if [[  "$response_status" != 20* ]] ; then
    echo "Response status is $response_status. Message from github API: $raw_result"
    exit
  fi
}

TEST_MODE="false"
# Check for the test flag
while getopts ":htw:" opt ; do
  case $opt in
    w)
      WORKFLOW_VERSION=$OPTARG
      ;;
    h)
      print_help
      ;;
    t)
      TEST_MODE=true
      ;;
    \?)
      printf "Invalid option: -$OPTARG\n\n">&2
      print_help
      ;;
    :)
      printf "Option -$OPTARG requires an argument.\n\n" >&2
      print_help
      ;;
  esac
done

if [ "$TEST_MODE" == "true" ] ; then
  echo "Test flag has been set. No commits will be made."
else
  echo "*** Test flag is NOT set. Commits WILL happen! ***"
fi


# Check that there is a github token file.
if [ ! -e github.token ] ; then
  echo "You must have a valid github authentication token, stored in a local file named \"github.token\". This process won\'t work without it."
  exit
fi

#TODO: refactor and use this function!
check_in_updated_file()
{
  file_name=$1
  path_in_repo=$2
  repo_name=$3
  # now check in the updated vars file.
  OLD_HASH_RESULT=$(curl -s -u `cat github.token`:x-oauth-basic https://api.github.com/repos/ICGC-TCGA-PanCancer/$repo_name/contents/$path_in_repo/$file_name --dump-header header.txt)
  process_curl_status "$OLD_HASH_RESULT"
  OLD_HASH=$( echo "$OLD_HASH_RESULT" | grep \"sha\" | sed 's/ *\"sha\": \"\([^ ]*\)\",/\1/g')
  ENCODED_FILE=$(base64 ~/$repo_name/$path_in_repo/$file_name | tr -d "\n")
  if [ "$TEST_MODE" == "false" ] ; then
    echo "Submitting updated $path_in_repo/$file_name for $repo_name"
    COMMIT_RESULT=$(curl -XPUT -s -u `cat github.token`:x-oauth-basic -H "Content-Type: application/json" -d '{"path":"'$file_name'","message":"Updated with new workflow version number","content":"'$ENCODED_FILE'","sha":"'$OLD_HASH'"}' https://api.github.com/repos/ICGC-TCGA-PanCancer/$repo_name/contents/$path_in_repo/$file_name --dump-header header.txt )
    process_curl_status "$COMMIT_RESULT"
  fi
}

if [  -n "$WORKFLOW_VERSION" ] ; then

  # update the vars file for George's workflow-update playbook so that it will download a new version of the workflow.
  sed -i -e 's/\(workflows: Workflow_Bundle_SangerPancancerCgpCnIndelSnvStr_\)\([^_]*\)\(_SeqWare_1.1.0-alpha.5\)/\1'$WORKFLOW_VERSION'\3/g' ~/pancancer-bag/workflow-update/roles/update_workflow/vars/main.yml
  check_in_updated_file "main.yml" "workflow-update/roles/udate_workflow/vars" "pancancer-bag"
  # now check in the updated vars file.
#  OLD_HASH_RESULT=$(curl -s -u `cat github.token`:x-oauth-basic https://api.github.com/repos/ICGC-TCGA-PanCancer/pancancer-bag/contents/workflow-update/roles/update_workflow/vars/main.yml --dump-header header.txt)
#  process_curl_status "$OLD_HASH_RESULT"
#  OLD_HASH=$( echo "$OLD_HASH_RESULT" | grep \"sha\" | sed 's/ *\"sha\": \"\([^ ]*\)\",/\1/g')
#  ENCODED_FILE=$(base64 ~/pancancer-bag/workflow-update/roles/update_workflow/vars/main.yml | tr -d "\n")
#  if [ "$TEST_MODE" == "false" ] ; then
#    echo "Submitting updated main.yml for pancancer-bag/workflow-update role"
#    #COMMIT_RESULT=$(curl -XPUT -s -u `cat github.token`:x-oauth-basic -H "Content-Type: application/json" -d '{"path":"main.yml","message":"Updated with new workflow","content":"'$ENCODED_FILE'","sha":"'$OLD_HASH'"}' https://api.github.com/repos/ICGC-TCGA-PanCancer/pancancer-bag/contents/workflow-update/roles/update_workflow/vars/main.yml --dump-header header.txt )
#    #process_curl_status "$COMMIT_RESULT"
#  fi

  # monitoring-bag also contains a reference to the workflow version so it also needs to be updated.
  # Update monitoring-bag/roles/client/vars/main.yml
  sed -i -e 's/\(workflow_version: SangerPancancerCgpCnIndelSnvStr_\)\([^_]*\)/\1'$WORKFLOW_VERSION'/g' ~/monitoring-bag/roles/client/vars/main.yml
  check_in_updated_file "main.yml" "roles/client/vars" "monitoring-bag"
#  OLD_HASH_RESULT=$(curl -s -u `cat github.token`:x-oauth-basic https://api.github.com/repos/ICGC-TCGA-PanCancer/monitoring-bag/contents/roles/client/vars/main.yml --dump-header header.txt)
#  process_curl_status "$OLD_HASH_RESULT"
#  OLD_HASH=$( echo "$OLD_HASH_RESULT" | grep \"sha\" | sed 's/ *\"sha\": \"\([^ ]*\)\",/\1/g')
#  ENCODED_FILE=$(base64 ~/monitoring-bag/roles/client/vars/main.yml | tr -d "\n")
#  if [ "$TEST_MODE" == "false" ] ; then
#    echo "Submitting updated main.yml for monitoring-bag/client role"
#    #COMMIT_RESULT=$(curl -XPUT -s -u `cat github.token`:x-oauth-basic -H "Content-Type: application/json" -d '{"path":"main.yml","message":"Updated with new workflow version","content":"'$ENCODED_FILE'","sha":"'$OLD_HASH'"}' https://api.github.com/repos/ICGC-TCGA-PanCancer/monitoring-bag/contents/roles/client/vars/main.yml --dump-header header.txt )
#    #process_curl_status "$COMMIT_RESULT"
#  fi
  
  #############################################################################
  #
  # Updates for workflow-decider
  sed -i -e 's/\(workflow-version=\)\(.*\)/\1'$WORKFLOW_VERSION'/g' ~/workflow-decider/conf/sites/decider.oicr.ini
  sed -i -e 's/\(pem-file=.*SangerPancancerCgpCnIndelSnvStr_\)\([^_]*\)\(.*\)/\1'$WORKFLOW_VERSION'\3/g' ~/workflow-decider/conf/sites/decider.oicr.ini
  OLD_HASH_RESULT=$(curl -s -u `cat github.token`:x-oauth-basic https://api.github.com/repos/ICGC-TCGA-PanCancer/workflow-decider/contents/conf/sites/decider.oicr.ini --dump-header header.txt)
  process_curl_status "$OLD_HASH_RESULT"
  OLD_HASH=$( echo "$OLD_HASH_RESULT" | grep \"sha\" | sed 's/ *\"sha\": \"\([^ ]*\)\",/\1/g')
  ENCODED_FILE=$(base64  ~/workflow-decider/conf/sites/decider.oicr.ini | tr -d "\n")
  if [ "$TEST_MODE" == "false" ] ; then
    echo "Submitting updated main.yml for monitoring-bag/client role"
    #COMMIT_RESULT=$(curl -XPUT -s -u `cat github.token`:x-oauth-basic -H "Content-Type: application/json" -d '{"path":"decider.oicr.ini","message":"Updated with new workflow version","content":"'$ENCODED_FILE'","sha":"'$OLD_HASH'"}' https://api.github.com/repos/ICGC-TCGA-PanCancer/workflow-decider/conf/sites/decider.oicr.ini --dump-header header.txt )
    #process_curl_status "$COMMIT_RESULT"
  fi

  # Updates for workflow-decider
  sed -i -e 's/\(workflow-version=\)\(.*\)/\1'$WORKFLOW_VERSION'/g' ~/workflow-decider/conf/sites/decider.etri.etri.ini
  OLD_HASH_RESULT=$(curl -s -u `cat github.token`:x-oauth-basic https://api.github.com/repos/ICGC-TCGA-PanCancer/workflow-decider/contents/conf/sites/decider.etri.etri.ini --dump-header header.txt)
  process_curl_status "$OLD_HASH_RESULT"
  OLD_HASH=$( echo "$OLD_HASH_RESULT" | grep \"sha\" | sed 's/ *\"sha\": \"\([^ ]*\)\",/\1/g')
  ENCODED_FILE=$(base64  ~/workflow-decider/conf/sites/decider.oicr.ini | tr -d "\n")
  if [ "$TEST_MODE" == "false" ] ; then
    echo "Submitting updated main.yml for monitoring-bag/client role"
    #COMMIT_RESULT=$(curl -XPUT -s -u `cat github.token`:x-oauth-basic -H "Content-Type: application/json" -d '{"path":"decider.etri.etri.ini","message":"Updated with new workflow version","content":"'$ENCODED_FILE'","sha":"'$OLD_HASH'"}' https://api.github.com/repos/ICGC-TCGA-PanCancer/workflow-decider/conf/sites/decider.etri.etri.ini --dump-header header.txt )
    #process_curl_status "$COMMIT_RESULT"
  fi

  sed -i -e 's/\(workflow-version=\)\(.*\)/\1'$WORKFLOW_VERSION'/g' ~/workflow-decider/conf/sites/decider.dkfz.32.ini
  OLD_HASH_RESULT=$(curl -s -u `cat github.token`:x-oauth-basic https://api.github.com/repos/ICGC-TCGA-PanCancer/workflow-decider/contents/conf/sites/decider.dkfz.32.ini --dump-header header.txt)
  process_curl_status "$OLD_HASH_RESULT"
  OLD_HASH=$( echo "$OLD_HASH_RESULT" | grep \"sha\" | sed 's/ *\"sha\": \"\([^ ]*\)\",/\1/g')
  ENCODED_FILE=$(base64  ~/workflow-decider/conf/sites/decider.oicr.ini | tr -d "\n")
  if [ "$TEST_MODE" == "false" ] ; then
    echo "Submitting updated main.yml for monitoring-bag/client role"
    #COMMIT_RESULT=$(curl -XPUT -s -u `cat github.token`:x-oauth-basic -H "Content-Type: application/json" -d '{"path":"decider.dkfz.32.ini","message":"Updated with new workflow version","content":"'$ENCODED_FILE'","sha":"'$OLD_HASH'"}' https://api.github.com/repos/ICGC-TCGA-PanCancer/workflow-decider/conf/sites/decider.oicr.ini --dump-header header.txt )
    #process_curl_status "$COMMIT_RESULT"
  fi

  sed -i -e 's/\(workflow-version=\)\(.*\)/\1'$WORKFLOW_VERSION'/g' ~/workflow-decider/conf/sites/decider.dkfz.64.ini
  sed -i -e 's/\(seqware-clusters="conf/cluster-\)\(.*\)\(\.json"\)/\1'$WORKFLOW_VERSION'\3/g' ~/workflow-decider/conf/sites/decider.dkfz.64.ini
  sed -i -e 's/\(report="workflow_decider_report_\)\(.*\)\(\.txt"\)/\1'$WORKFLOW_VERSION'\3/g' ~/workflow-decider/conf/sites/decider.dkfz.64.ini
  OLD_HASH_RESULT=$(curl -s -u `cat github.token`:x-oauth-basic https://api.github.com/repos/ICGC-TCGA-PanCancer/workflow-decider/contents/conf/sites/decider.dkfz.64.ini --dump-header header.txt)
  process_curl_status "$OLD_HASH_RESULT"
  OLD_HASH=$( echo "$OLD_HASH_RESULT" | grep \"sha\" | sed 's/ *\"sha\": \"\([^ ]*\)\",/\1/g')
  ENCODED_FILE=$(base64  ~/workflow-decider/conf/sites/decider.oicr.ini | tr -d "\n")
  if [ "$TEST_MODE" == "false" ] ; then
    echo "Submitting updated main.yml for monitoring-bag/client role"
    #COMMIT_RESULT=$(curl -XPUT -s -u `cat github.token`:x-oauth-basic -H "Content-Type: application/json" -d '{"path":"decider.dkfz.64.ini","message":"Updated with new workflow version","content":"'$ENCODED_FILE'","sha":"'$OLD_HASH'"}' https://api.github.com/repos/ICGC-TCGA-PanCancer/workflow-decider/conf/sites/decider.dkfz.64.ini --dump-header header.txt )
    #process_curl_status "$COMMIT_RESULT"
  fi

else
  echo "You must give a workflow version."
  print_help
  exit
fi
