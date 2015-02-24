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
            ;;
    esac
done
# echo "$GIT_USER"
LOG_FILE=$(basename $BASH_SOURCE).log
echo "[ Begin Log, "$(date)" ]">>$LOG_FILE
{

echo "architecture-setup version: $VERSION_NUM"
VARS_PATH=roles/bindle-profiles/vars
VARS_FILE=$VARS_PATH/main.yml

# Before trying to upgrade anything, make sure none of the repos have changed files. 
# It's better to do it now than to let Ansible get halfway through the playbook (it could take
# a few minutes!) and then fail.
REPOS=( ~/architecture2/pancancer-bag ~/architecture2/monitoring-bag ~/architecture2/Bindle ~/architecture2/seqware-bag ~/architecture2/workflow-decider ~/architecture-setup )
echo "Do any of your architecture2 repos have changes in them?"
REPOS_HAVE_CHANGES=0
for r in "${REPOS[@]}"
do
  if [ -d $r ] ; then
    cd $r
    NUM_CHANGES=$(git status --short -uno | grep '^[^?]\{2\}' | wc --lines)
    echo "$NUM_CHANGES in $r"
    if [ "$NUM_CHANGES" -gt 0 ] ; then
      printf "You cannot upgrade architecture-setup until you resolve $NUM_CHANGES potential repository conflicts in $r (untracked files NOT shown)\n\n"
      # let's actually *show* them the issues (but ignore the untracked files), in summary.
      git status --short -uno
      REPOS_HAVE_CHANGES=1
    fi
  fi
done
if [ "$REPOS_HAVE_CHANGES" -eq 1 ] ; then
  echo "Some repositories have changes in tracked files. Please fix this before continuing. Now exiting..."
  exit
fi

cd ~/architecture-setup
CHECKOUT_MESSAGE=$(git checkout $VERSION_NUM 2>&1)
# If there are checkout errors, display them...
if [[ "$CHECKOUT_MESSAGE" =~ .*error.* ]] ; then
  echo "Could not checkout architecture-setup $VERSION_NUM. Error message is:"
  echo $CHECKOUT_MESSAGE
  exit
# ...Otherwise, run the ansible playbook.
else
  echo $CHECKOUT_MESSAGE
  echo "Running architecture-setup with updated dependencies..."
  export PYTHONUNBUFFERED=1
  ansible-playbook -i inventory site.yml
fi
} | tee -a $LOG_FILE
echo "[ End Log, "$(date)" ]">>$LOG_FILE
