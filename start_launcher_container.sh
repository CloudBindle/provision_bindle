#! /bin/bash

RESTART_POLICY="\n\t--restart=always"
POST_START_CMD=/home/ubuntu/start_services_in_container.sh
TEST_RESULT_VOLMUE=
INTERACTIVE=" -i "
MOUNTED_VOLUME_PREFIX="/home/$USER"

set -e
while [[ $# > 0 ]] ; do
  key="$1"
  case $key in
    -p|--pem_key)
      PEM_KEY="$2"
      shift
    ;;
    -i|--image_version)
      IMAGE_VERSION="$2"
      shift
    ;;
    -e|--host_env)
      HOST_ENV="$2"
      shift
    ;;
    -t|--test_mode)
      E2E_TEST="$2"
      shift
    ;;
    -f|--fleet_name)
      FLEET_NAME="$2"
      shift
    ;;
    --target_env)
      TARGET_ENV="$2"
      shift
    ;;
    -h|--help)
    cat <<HELP_MESSAGE
This script will start up pancancer_launcher.

Options are:
  -p, --pem_key - The path to the pem key file you want to use to start up new workers.
  -i, --image_version - The version of pancancer_launcher you want to run.
  -e, --host_env - The host environment you are running in (Either "AWS", "OpenStack", or "Azure"). If you do not specify a value, "AWS" will be defaulted.
  -t, --test_mode - Run in test mode (lauches workers immediately when container starts). Defaults to "false"
  -f, --fleet_name - The name of the fleet of workers that will be managed by this launcher. If you do not specify one, a random name will be generated.
  --target_env - Only used when running in test mode.
  -h, --help - Prints this message.
HELP_MESSAGE
      exit 0
    ;;
  esac
  shift
done

if [ -z $FLEET_NAME ] ; then
  FLEET_NAME="$( < /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c12 )"
  echo "You did not specify a fleet name, so a random name has been generated for your fleet: ${FLEET_NAME}"
fi
# HOST_ENV is used *inside* the container to determine how to get the PUBLIC_IP_ADDRESS.
# Options are: AWS, OPENSTACK, local
if [ -z $HOST_ENV ] ; then
  HOST_ENV="AWS"
fi

# User must specify a PEM key and it must be a valid file.
if [ -z $PEM_KEY ] ; then
  echo "You must pass the path to a valid key file for the \"-p\" option."
  exit 1
else
  if [ ! -f $PEM_KEY ] ; then
    echo "The path you pass for the key file must be valid. Please ensure that \"$PEM_KEY\" is a valid path."
    exit 1
  fi
fi

# User must specify an image version.
if [ -z $IMAGE_VERSION ] ; then
  echo "You must pass an image version for the \"-i\" option."
  exit 1
fi

WORKER_NAME=e2e_test_node

ENVS="OpenStack AWS Azure local"

# There are three options for environment: AWS, OPENSTACK, local
if [[ ! $ENVS =~ .*"${HOST_ENV}".* ]] ; then
  echo "The value for HOST_ENV (third argument) must be one of: OpenStack, AWS, Azure, local"
  exit 1;
fi

# If the user is requesting an end-to-end integration test, there's some additional setup work.
if [[ -n $E2E_TEST && "$E2E_TEST" = "true" ]] ; then
  # e2e test should not restart, it could break automation.
  RESTART_POLICY=
  INTERACTIVE=
  MOUNTED_VOLUME_PREFIX=$PWD
  # user *must* specify if they want to test against AWS or OpenStack, if they are running the launcher in a local context (i.e. their personal workstation)
  if [ "$HOST_ENV" = "local" ] ; then
    if [ -z $TARGET_ENV ] ; then
      echo "If you are running your container locally (not in a cloud environment), you MUST specify a worker type as \"--target_env ENV\" for this script (either \"aws\" or \"openstack\")."
      exit 1
    else
      WORKER_TYPE=$TARGET_ENV
    fi
  else
    WORKER_TYPE=$HOST_ENV
  fi
  # This command will launch workers once the container starts
  POST_START_CMD="$POST_START_CMD /home/ubuntu/launch_workers.sh ${WORKER_TYPE,,} $WORKER_NAME"
  # Add a shared volume for test results.
  TEST_RESULT_VOLUME="\n\t-v $MOUNTED_VOLUME_PREFIX/pancancer_launcher_test_results:/opt/from_host/test_results:rw"
else
  POST_START_CMD="$POST_START_CMD"
fi

# Create a folder that will be mounted into the docker container
[[ -d "$MOUNTED_VOLUME_PREFIX/pancancer_launcher_ssh" ]] || mkdir "$MOUNTED_VOLUME_PREFIX/pancancer_launcher_ssh"

# Create a config folder if there isn't one already.
[[ -d "$MOUNTED_VOLUME_PREFIX/pancancer_launcher_config" ]] || mkdir "$MOUNTED_VOLUME_PREFIX/pancancer_launcher_config"

# create the ~/.aws folder, if it doesn't already exist
[[ -d "$MOUNTED_VOLUME_PREFIX/.aws" ]] || mkdir "$MOUNTED_VOLUME_PREFIX/.aws"

# Create the ~/.gnos folder if it is not there
[[ -d "$MOUNTED_VOLUME_PREFIX/.gnos" ]] || mkdir "$MOUNTED_VOLUME_PREFIX/.gnos"

# Copy the pem file in $1 to the folder for the container.
PEM_KEY_BASENAME=$(basename $PEM_KEY)
[[ -f $MOUNTED_VOLUME_PREFIX/pancancer_launcher_ssh/$PEM_KEY_BASENAME ]] || cp $PEM_KEY $MOUNTED_VOLUME_PREFIX/pancancer_launcher_ssh/$PEM_KEY_BASENAME

cat <<ARGS_MESSAGE
Specified arguments are:
  PEM key:          $PEM_KEY
  Image version:    $IMAGE_VERSION
  Host environment: $HOST_ENV
  Fleet name:       $FLEET_NAME
  Test mode:        $E2E_TEST
ARGS_MESSAGE
# If running the container on a workstation, the Public IP address should be that of the host machine, so this needs to be passed into the container as a variable.
if [ "$HOST_ENV" = "local" ] ; then
  PUBLIC_IP_ADDRESS=$(ip addr show eth0 | grep "inet " | sed 's/.*inet \(.*\)\/.*/\1/g')
  if [ -n $PUBLIC_IP_ADDRESS ] ; then
    PUBLIC_IP_ADDRESS_STR="\n\t-e HOST_PUBLIC_IP_ADDRESS=$PUBLIC_IP_ADDRESS"
    cat <<ARGS_MESSAGE
  Host IP address:  $PUBLIC_IP_ADDRESS
ARGS_MESSAGE
  fi
fi
# Some additional parameters needs to be passed in on AWS for security group updates
if [ "$HOST_ENV" = "AWS" ] ; then
  INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id)
  if [ -n $INSTANCE_ID ] ; then
    INSTANCE_ID_STR="\n\t-e HOST_INSTANCE_ID=$INSTANCE_ID"
    cat <<ARGS_MESSAGE
  Instnance ID:  $INSTANCE_ID
ARGS_MESSAGE
  fi
fi

DOCKER_CMD=$(cat <<CMD_STR
sudo docker run $INTERACTIVE -t -P --privileged=true --name pancancer_launcher
        -v $MOUNTED_VOLUME_PREFIX/pancancer_launcher_config:/opt/from_host/config:rw
        -v $MOUNTED_VOLUME_PREFIX/pancancer_launcher_ssh:/opt/from_host/ssh:ro
        -v $MOUNTED_VOLUME_PREFIX/.aws/:/opt/from_host/aws:ro
        -v $MOUNTED_VOLUME_PREFIX/.gnos/:/opt/from_host/gnos:ro
        -v /etc/localtime:/etc/localtime:ro $TEST_RESULT_VOLUME $PUBLIC_IP_ADDRESS_STR $INSTANCE_ID_STR $RESTART_POLICY
        -p 15672:15672
        -p 5671:5671
        -p 5672:5672
        -p 4567:4567
        -p 8080:8080
        -p 3000:3000
        -e FLEET_NAME=$FLEET_NAME
        -e HOST_ENV=$HOST_ENV
        -e PATH_TO_PEM=/opt/from_host/ssh/$PEM_KEY_BASENAME
        --add-host sensu-server:127.0.0.1
        pancancer/pancancer_launcher:$IMAGE_VERSION $POST_START_CMD

CMD_STR
)

echo "The command that will be executed is:"

echo -e "$DOCKER_CMD"
set +e
$(echo -e "$DOCKER_CMD")
