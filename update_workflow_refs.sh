#!/bin/bash 
# This script will update files in pancancer-bag and monitoring-bag.
# TODO: Also update: workflow-decider: conf/sites/decider.oicr.ini ; conf/sites/decider.dkfz.32.ini ; conf/sites/decider.dkfz.64.ini ; cron/status.aws-oregon.cron ; cron/status.aws-ireland.cron
set -e

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
UPDATED_FILES=()
update_file_in_repo()
{
  file_name=$1
  path_in_repo=$2
  repo_name=$3
  repo_root_dir=$4
  cd ~/$repo_root_dir/$repo_name
  echo "Checking for differences in file: $repo_name/$path_in_repo/$file_name"
  # disable exit on error - I think git diff or grep is returning with non-0 exit code when
  # there are no file differences, but I'm OK with that, it just means the file hasn't changed.
  set +e 
  #git_diff=$(git --no-pager diff  --stat=80,500 -- $path_in_repo/$file_name | grep "$path_in_repo/$file_name" )
  git_diff=$(git --no-pager diff --name-status -- $path_in_repo/$file_name | grep "$path_in_repo/$file_name" )
  set -e
  #If the file changed as a result of updating the version number, show the diffs and check in the file.
  if [ -n "$git_diff" ] ; then
    
    echo "Differences in $path_in_repo/$file_name"
    git --no-pager diff  -- $path_in_repo/$file_name
    echo "File will be checked in."

    cd ~/architecture-setup
    URL="https://api.github.com/repos/ICGC-TCGA-PanCancer/$repo_name/contents/$path_in_repo/$file_name"
    echo "updating file: $URL"
    OLD_HASH_RESULT=$(curl -s -u `cat github.token`:x-oauth-basic $URL --dump-header header.txt)
    process_curl_status "$OLD_HASH_RESULT"
    OLD_HASH=$( echo "$OLD_HASH_RESULT" | grep \"sha\" | sed 's/ *\"sha\": \"\([^ ]*\)\",/\1/g')
    ENCODED_FILE=$(base64 ~/$repo_root_dir/$repo_name/$path_in_repo/$file_name | tr -d "\n")
    if [ "$TEST_MODE" == "false" ] ; then
      echo "Submitting updated $path_in_repo/$file_name for $repo_name"
      COMMIT_RESULT=$(curl -XPUT -s -u `cat github.token`:x-oauth-basic -H "Content-Type: application/json" -d '{"path":"'$file_name'","message":"Updated with new workflow version number","content":"'$ENCODED_FILE'","sha":"'$OLD_HASH'"}' https://api.github.com/repos/ICGC-TCGA-PanCancer/$repo_name/contents/$path_in_repo/$file_name --dump-header header.txt )
      process_curl_status "$COMMIT_RESULT"
      UPDATED_FILES+=( "$repo_name/$path_in_repo/$file_name" )
    fi
  else
    echo "File $path_in_repo/$file_name has not changed and will NOT be checked in."
  fi
  printf "\n"
}


LOG_FILE=$(basename $BASH_SOURCE).log
echo "[ Begin Log, "$(date)" ]">>$LOG_FILE
{
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

if [  -n "$WORKFLOW_VERSION" ] ; then
  # update the vars file for George's workflow-update playbook so that it will download a new version of the workflow.
  sed -i -e 's/\(workflows: Workflow_Bundle_SangerPancancerCgpCnIndelSnvStr_\)\([^_]*\)\(_SeqWare_1.1.0-alpha.5\)/\1'$WORKFLOW_VERSION'\3/g' ~/architecture2/pancancer-bag/workflow-update/roles/update_workflow/vars/main.yml
  update_file_in_repo "main.yml" "workflow-update/roles/update_workflow/vars" "pancancer-bag" "architecture2"

  # monitoring-bag also contains a reference to the workflow version so it also needs to be updated.
  # Update monitoring-bag/roles/client/vars/main.yml
  sed -i -e 's/^\(workflow_version: SangerPancancerCgpCnIndelSnvStr_\)\([^_]*\)/\1'$WORKFLOW_VERSION'/g' ~/architecture2/monitoring-bag/roles/client/vars/main.yml
  update_file_in_repo "main.yml" "roles/client/vars" "monitoring-bag" "architecture2"

  # architecture-setup has a reference to the workflow version.
  sed -i -e 's/^\(workflow_version: \)\(\".*\"\)/\1\"'$WORKFLOW_VERSION'\"/g' ~/architecture-setup/roles/bindle-profiles/vars/main.yml
  update_file_in_repo "main.yml" "roles/bindle-profiles/vars" "architecture-setup" "" 

  #############################################################################
  #
  # Updates for workflow-decider
  sed -i -e 's/^\(workflow-version=\)\(.*\)/\1'$WORKFLOW_VERSION'/g' ~/architecture2/workflow-decider/conf/sites/decider.oicr.ini
  sed -i -e 's/\(pem-file=.*SangerPancancerCgpCnIndelSnvStr_\)\([^_]*\)\(.*\)/\1'$WORKFLOW_VERSION'\3/g' ~/architecture2/workflow-decider/conf/sites/decider.oicr.ini
  update_file_in_repo "decider.oicr.ini" "conf/sites" "workflow-decider" "architecture2"

  sed -i -e 's/^\(workflow-version=\)\(.*\)/\1'$WORKFLOW_VERSION'/g' ~/architecture2/workflow-decider/conf/decider.ini
  update_file_in_repo "decider.ini" "conf" "workflow-decider" "architecture2"

         printf "\n##########################\n${#UPDATED_FILES[@]} files that were updated:\n"
  for r in "${UPDATED_FILES[@]}" 
  do
    echo $r
  done

else
  printf "You must give a workflow version.\n\n"
  print_help
  exit
fi
} | tee -a $LOG_FILE
echo "[ End Log, "$(date)" ]">>$LOG_FILE
