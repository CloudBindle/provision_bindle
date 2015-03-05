#!/bin/bash
VERSION_NUM=""
LOG_FILE=$(basename $BASH_SOURCE).log
echo "[ Begin Log, "$(date)" ]">>$LOG_FILE
{

while getopts "hv:" opt; do
    case "$opt" in
      \?)
            #echo "Option -$opt requires an argument"
            exit 1
            ;;
       :)
            echo "Option -v is required."
            exit 1
            ;;
       v)
            VERSION_NUM=$OPTARG
            ;;
       h)
cat <<xxxEndOfHelpxxx
Upgrade architecture-setup:

This script will upgrade your current architecture-setup by checking out a
specified label of architecture-setup, and then running the architecture-
setup playbook.

This process will fail if you have modified any files in the architecture-setup
submodule repositories that are tracked by git.

Options:
  -v <version number>	- A version of architecture-setup that you wish to
                          upgrade.
  -h			- Prints this help text.
xxxEndOfHelpxxx
            exit 1
            ;;
    esac
done
if [ -z $VERSION_NUM ] ; then
  echo "You must specify a verion of architecture-setup with -v"
  exit 1
fi
echo "architecture-setup version: $VERSION_NUM"
VARS_PATH=roles/bindle-profiles/vars
VARS_FILE=$VARS_PATH/main.yml

# Before trying to upgrade anything, make sure none of the repos have changed files. 
# It's better to do it now than to let Ansible get halfway through the playbook (it could take
# a few minutes!) and then fail.
REPOS=( ~/architecture-setup/pancancer-bag ~/architecture-setup/monitoring-bag ~/architecture-setup/Bindle ~/architecture-setup/seqware-bag ~/architecture-setup/workflow-decider  )
echo "Do any of your repos have changes in them?"
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
  exit 1
fi

cd ~/architecture-setup
CURRENT_VERSION=$(git name-rev --tags --name-only $(git rev-parse HEAD))
if [ "$CURRENT_VERSION" == "$VERSION_NUM" ] ; then
  echo "Your local architecture-setup is already at $CURRENT_VERSION, and there are no known differences in any of your repositories. The ansible playbook will not be run, as it is not necessary."
  exit 0
fi
CHECKOUT_MESSAGE=$(git checkout $VERSION_NUM 2>&1)
# If there are checkout errors, display them...
if [[ "$CHECKOUT_MESSAGE" =~ .*error.* ]] ; then
  echo "Could not checkout architecture-setup $VERSION_NUM. Error message is:"
  echo $CHECKOUT_MESSAGE
  exit 1
# ...Otherwise, run the ansible playbook.
else
  echo $CHECKOUT_MESSAGE
  echo "Running architecture-setup with updated dependencies..."
  export PYTHONUNBUFFERED=1
  ansible-playbook -i inventory site.yml
fi
} | tee -a $LOG_FILE
# because the script executes inside "{...} | tee", we need to capture the exit code
# before writing the last line of th log file, and then return THAT exit code.
SCRIPT_EXIT_CODE=${PIPESTATUS[0]}
echo "[ End Log, "$(date)" ]">>$LOG_FILE
exit $SCRIPT_EXIT_CODE
