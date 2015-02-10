#!/bin/bash

# Check that there is a github token file.
if [ ! -e github.token ] ; then
  echo You must have a valid github authentication token, stored in a local file named \"github.token\". This process won\'t work without it.
  exit
fi

# Check that the user provided a tag name.
# TODO: Agree on a way to generate tag names automatically.
NEW_TAG=$1
if [ "$NEW_TAG" = '' ] ; then 
  echo You must provide a tag name for any releases that will be created! Exiting.
  exit
fi

declare -a info

# This function will get the published_at date and tag_name of the most recent release of architecture-setup
get_latest_release()
{
  filtered_result=$(curl -u `cat github.token`:x-oauth-basic https://api.github.com/repos/ICGC-TCGA-PanCancer/architecture-setup/releases |  jq '[ .[] | {"p": .published_at, "t": .tag_name  }] | sort_by(.p) | reverse | .[0]')
  info=( "$(echo $filtered_result | grep \"t\": | sed 's/.* \"t\": \"\([^\"]*\)\".*/\1/g')" "$(echo $filtered_result | grep \"p\": | sed 's/.* \"p\": \"\([^\"]*\)\".*/\1/g')" )
}

get_latest_release
RELEASE_DATE=${info[1]}
TAG=${info[0]}
echo Most recent release date: $RELEASE_DATE
echo Most recen release tag: $TAG

#These repositories will be examined for commits that have occured since the date of the last architecture-setup release.
REPOS=("ICGC-TCGA-PanCancer/pancancer-bag" "ICGC-TCGA-PanCancer/monitoring-bag" "ICGC-TCGA-PanCancer/workflow-decider" "SeqWare/seqware-bag" "CloudBindle/Bindle")
declare -A REPO_VARS
REPO_VARS=( ['ICGC-TCGA-PanCancer/pancancer-bag']=pancancer_bag_git_branch ['ICGC-TCGA-PanCancer/monitoring-bag']=monitoring_bag_git_branch ['ICGC-TCGA-PanCancer/workflow-decider']=decider_git_branch ['SeqWare/seqware-bag']=seqware_bag_git_branch ['CloudBindle/Bindle']=bindle_git_branch )
declare -A REPO_VAR_VERS

#REPOS=(ICGC-TCGA-PanCancer/workflow-decider)
for r in "${REPOS[@]}"
do
  echo Checking for new commits in $r...;
  NUM_COMMITS=$(curl -s -u `cat github.token`:x-oauth-basic https://api.github.com/repos/$r/commits?since=$RELEASE_DATE | jq 'length');
  echo Number of commits since most recent release: $NUM_COMMITS
  if [ $NUM_COMMITS -gt 0 ] ; then
    printf "New release must be created!\nRelease will be tagged as: $NEW_TAG\n\n"
    # Create the new tag on the repo for the release. TODO: The value for "draft" could be a parameter. Also, the value for "body".
#    RESULT=$(curl -u `cat github.token`:x-oauth-basic -H "Content-Type: application/json" -d '{"tag_name": "'$NEW_TAG'", "name": "'$NEW_TAG'", "body": "Generated release", "draft": true}'  https://api.github.com/repos/$r/releases )
#    echo $RESULT
    REPO_VAR_VERS[$r]=$NEW_TAG
  else
    printf "No new commits, no new release is needed.\n\n"
  fi
done

# Now, we need to update roles/bindle-profiles/vars/main.yml
for r in "${!REPO_VAR_VERS[@]}"
do
#  echo key: $r
#  echo value: ${REPO_VAR_VERS[$r]}
#  echo var name: ${REPO_VARS[$r]}
  sed -i 's/'${REPO_VARS[$r]}': \".*\"/'${REPO_VARS[$r]}': \"'${REPO_VAR_VERS[$r]}'\"/g' ./roles/bindle-profiles/vars/main.yml
done

FILECONTENTS=$(cat ./roles/bindle-profiles/vars/main.yml)
printf "Updated ./roles/bindle-profiles/vars/main.yml is:\n$FILECONTENTS\n"

# Update main.yml in repo
OLD_HASH=$(curl -s -u `cat github.token`:x-oauth-basic https://api.github.com/repos/ICGC-TCGA-PanCancer/architecture-setup/contents/roles/bindle-profiles/vars/main.yml?ref=feature/upgrade_launcher_script | grep \"sha\" | sed 's/ *\(\"sha\": \"[^ ]*\"\),/\1/g')
#echo $OLD_HASH
FILESIZE=$(stat -c%s ./roles/bindle-profiles/vars/main.yml)
#HASH=$(echo -e "blob $FILESIZE\0$FILECONTENTS" | shasum -t | sed 's/\(.*\) -/\1/g')
#HASH=$(git hash-object ./roles/bindle-profiles/vars/main.yml)
ENCODED_FILE=$(base64 -w 0 roles/bindle-profiles/vars/main.yml)
JSON_DATA="{\"path\":\"main.yml\",\"message\":\"Updated with new versions of dependencies\",\"content\":\"$ENCODED_FILE\",$OLD_HASH,\"branch\":\"feature/upgrade_launcher_script\"}"
echo $JSON_DATA
COMMIT_RESULT=$(curl -v -XPUT -u `cat github.token`:x-oauth-basic -H "Content-Type: application/json" -d '"/'"$JSON_DATA"'/"' https://api.github.com/repos/ICGC-TCGA-PanCancer/architecture-setup/contents/roles/bindle-profiles/vars/main.yml )
echo $COMMIT_RESULT
