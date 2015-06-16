#! /usr/bin/bash

PEM_KEY=$1
IMAGE_VERSION=$2
HOST_ENV=$3
E2E_TEST=$4
RESTART_POLICY="\n\t--restart=always"
POST_START_CMD=/bin/bash
TEST_RESULT_VOLMUE=

# HOST_ENV is used *inside* the container to determine how to get the PUBLIC_IP_ADDRESS.
# Options are: AWS, OPENSTACK, local
if [ -z $HOST_ENV ] ; then
  HOST_ENV="AWS"
fi

# User must specify a PEM key and it must be a valid file.
if [ -z $PEM_KEY ] ; then
  echo "You must pass the path to a valid key file as the first argument."
  exit 1
else
  if [ ! -f $PEM_KEY ] ; then
    echo "The path you pass for the key file must be value. Please ensure that $PEM_KEY is a valid path."
    exit 1
  fi
fi

# User must specify an image version.
if [ -z $IMAGE_VERSION ] ; then 
  echo "You must pass an image version as the second argument."
  exit 1
fi

WORKER_NAME=e2e_test_node

ENVS="OPENSTACK AWS local"

# There are three options for environment: AWS, OPENSTACK, local
if [[ ! $ENVS =~ .*"${HOST_ENV}".* ]] ; then
  echo "The value for HOST_ENV (third argument) must be one of: OPENSTACK, AWS, local"
  exit 1;
fi

# If the user is requesting an end-to-end integration test, there's some additional setup work.
if [[ -n $E2E_TEST && $E2E_TEST == 'true' ]] ; then
  # e2e test should not restart, it could break automation.
  RESTART_POLICY=
  # user *must* specify if they want to test against AWS or OpenStack, if they are running the launcher in a local context (i.e. their personal workstation)
  if [ $HOST_ENV == 'local' ] ; then
    if [ -z $5 ] ; then 
      echo "If you are running your container locally (not in a cloud environment), you MUST specify a worker type as the fourth argument for this script (either \"aws\" or \"openstack\")."
      exit 1
    else
      WORKER_TYPE=$5
    fi
  else
    WORKER_TYPE=$HOST_ENV
  fi
  # This command will launch workers once the container starts
  POST_START_CMD="\"/bin/bash /home/ubuntu/launch_workers.sh ${WORKER_TYPE,,} $WORKER_NAME /bin/bash\""
  # Add a shared volume for test results.
  TEST_RESULT_VOLUME="\n\t-v /home/$USER/pancancer_launcher_test_results:/opt/from_host/test_results:rw"
fi


# Create a folder that will be mounted into the docker container
[[ -d ~/pancancer_launcher_ssh ]] || mkdir ~/pancancer_launcher_ssh

# Create a config folder if there isn't one already.
[[ -d ~/pancancer_launcher_config ]] || mkdir ~/pancancer_launcher_config

# create the ~/.aws folder, if it doesn't already exist
[[ -d ~/.aws/ ]] || mkdir ~/.aws

# Create the ~/.gnos folder if it is not there
[[ -d ~/.gnos/ ]] || mkdir ~/.gnos

# Copy the pem file in $1 to the folder for the container.
PEM_KEY_BASENAME=$(basename $PEM_KEY)
[[ -f ~/pancancer_launcher_ssh/$PEM_KEY_BASENAME ]] || cp $PEM_KEY ~/pancancer_launcher_ssh/$PEM_KEY_BASENAME


DOCKER_CMD=$(cat <<CMD_STR
docker run -i -t -P --privileged=true --name pancancer_launcher 
        -v /home/$USER/pancancer_launcher_config:/opt/from_host/config:rw 
        -v /home/$USER/pancancer_launcher_ssh:/opt/from_host/ssh:ro         $TEST_RESULT_VOLUME
        -v /home/$USER/.aws/:/opt/from_host/aws:ro 
        -v /home/$USER/.gnos/:/opt/from_host/gnos:ro 
	-v /etc/localtime:/etc/localtime:ro         $RESTART_POLICY
        -p 15672:15672 
        -p 5671:5671 
        -p 5672:5672 
        -p 4567:4567 
        -p 8080:8080 
        -p 3000:3000 
        -e "HOST_ENV=$HOST_ENV" 
        -e "PATH_TO_PEM=/opt/from_host/ssh/$PEM_KEY_BASENAME" 
        --add-host sensu-server:127.0.0.1 
        pancancer/pancancer_launcher:$IMAGE_VERSION /bin/bash /home/ubuntu/start_services_in_container.sh $POST_START_CMD 
CMD_STR
)

#DOCKER_CMD=$( echo -e "$DOCKER_CMD" | sed s/$/\\\\/g )
#DOCKER_CMD=$( echo -e "$DOCKER_CMD" | sed '$ s/.$//g' )

echo "The command that will be executed is:"
echo -e "$DOCKER_CMD"
$(echo -e "$DOCKER_CMD")
