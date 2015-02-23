#!/bin/bash
CURL_USER=""
GIT_USER=""
CURL_URL_PARAM=""
VERSION_NUM=""
while getopts "h :u:v:" opt; do
    case "$opt" in
        u)  #TODO: Add the ability to authenticate with a github token file.
            CURL_USER=" -u $OPTARG"
            GIT_USER="$OPTARG"
            ;;
        v)
            CURL_URL_PARAM="ref=$OPTARG"
            VERSION_NUM=$OPTARG
            ;;
        h)
cat <<xxxEndOfHelpxxx
Upgrade architecture-setup:

This script will upgrade your current architecture-setup by downloading a newer
version of the ansible file which contains references to architecture-setup's
dependency repositories. 

A backup of your old main.yml file will be created before the new one is
downloaded.

Options:
  -u <github user name>	- A github username to use for authentication with the
                          github API when downloading files.
                          This is not necessary, but it is a good idea.
                          Unauthenticated requests to the API may restricted to
                          a certain number of respones per hour, per IP address.

  -v <version number>	- A version of architecture-setup that you wish to
                          upgrade.
                          This is optional.
                          If left blank, no version number will be sent to
                          github and
                          by default, the most recent version will be
                          downloaded.

  -h			- Prints this help text.
xxxEndOfHelpxxx
            exit
    esac
done
echo "$GIT_USER"
echo "architecture-setup version: $VERSION_NUM"
VARS_PATH=roles/bindle-profiles/vars
VARS_FILE=$VARS_PATH/main.yml

# Before trying to upgrade anything, make sure none of the repos have changed files. 
# It's better to do it now than to let Ansible get halfway through the playbook (it could take
# a few minutes!) and then fail.
REPOS=( ~/architecture2/pancancer-bag ~/architecture2/monitoring-bag ~/architecture2/Bindle ~/architecture2/seqware-bag ~/architecture2/workflow-decider )
echo "Do any of your architecture2 repos have changes in them?"
for r in "${REPOS[@]}"
do
  cd $r
  NUM_CHANGES=$(git status --short -uno | grep '^[^?]\{2\}' | wc --lines)
  echo "$NUM_CHANGES in $r"
  if [ "$NUM_CHANGES" -gt 0 ] ; then
    printf "You cannot upgrade architecture-setup until you resolve $NUM_CHANGES potential repository conflicts in $r (untracked files NOT shown)\n\n"
    # let's actually *show* them the issues (but ignore the untracked files), in summary.
    git status --short -uno
    exit
  fi
done
cd ~/architecture-setup
# let's back up the old one, just in case they still want it.
DATE_STR=$(date +%Y%m%d_%H%M%S)
cp $VARS_FILE $VARS_PATH/main_${DATE_STR}_yml.bkup

RESPONSE=$(curl -s ${CURL_USER} https://api.github.com/repos/ICGC-TCGA-PanCancer/architecture-setup/contents/roles/bindle-profiles/vars/main.yml?"$CURL_URL_PARAM")

if [[ $RESPONSE =~ \"message\"\: ]] ; then 
    MESSAGE=$(echo $RESPONSE | sed 's/{ \"message\"\: \"\([^\"]*\).*$/\1/g')
    echo "A message was detected:"
    echo \"$MESSAGE\"
else
    # TODO: Find a nice clean way to do these four commands in a single step in bash. It worked from the command line, not sure why it didn't work right in script.

    # find the line with content.
    RESPONSE_1=$(echo $RESPONSE | grep \"content\")
    # Response will actually contain "\n" so that it can be nicely formatted, but that will break base64 decode so we need to remove them.
    RESPONSE_2=$(echo $RESPONSE_1 | sed 's/\\n//g')
    # Extract just the encoded conent
    RESPONSE_3=$(echo $RESPONSE_2 | sed 's/.* *\"content\": \"\([^\"]*\).*/\1/g')
    # Decode to file.
    echo $RESPONSE_3 | base64 --decode > $VARS_FILE
    FILESIZE=$(stat -c%s "$VARS_FILE")
    if [ $FILESIZE == 0 ] ; then 
        echo "Error! No file was downloaded for version $VERSION_NUM"
    else
        echo "File downloaded to $VARS_FILE"
        #If file download was OK, run ansible
        echo "Running architecture-setup with updated dependencies..."
        ansible-playbook -i inventory site.yml
    fi
fi


