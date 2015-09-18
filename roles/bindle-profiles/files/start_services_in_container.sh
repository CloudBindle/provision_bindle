#! /bin/bash

cat <<INTRO_MESSAGE


*****************************
* Now running inside        *
* the pancancer_launcher... *
*****************************

Setting up. This may take a few moments...

INTRO_MESSAGE

exec 3>&1 4>&2 1>>~/startup.log 2>&1
echo -e "\n\n[BEGIN: $(date +%Y-%m-%d_%H:%M:%S)]"

# Copy pem keys and other config files from the host.
echo "Copying $PATH_TO_PEM to ~/.ssh/"
cp $PATH_TO_PEM ~/.ssh/
echo "Updating permissions on ~/.ssh/$(basename $PATH_TO_PEM)"
chmod 600 ~/.ssh/$(basename $PATH_TO_PEM)

echo "Copying GNOS keys to ~/.gnos"
cp /opt/from_host/gnos/* ~/.gnos/

echo "Copying.aws credentials to ~/.aws"
cp /opt/from_host/aws/* ~/.aws/

echo "HOST_ENV is $HOST_ENV"

if [ "$HOST_ENV" == "AWS" ] ; then
  echo "Querying AWS for public IP address of this machine..."
  export PUBLIC_IP_ADDRESS=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)
  export SENSU_SERVER_IP_ADDRESS=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
  python ~/update_security_groups.py $HOST_INSTANCE_ID $PUBLIC_IP_ADDRESS
elif [ "$HOST_ENV" == "OPENSTACK" ] ; then
  # Looks like the OpenStack metadata IP address is the same as AWS
  echo "Querying OpenStack for public IP address of this machine..."
  export PUBLIC_IP_ADDRESS=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)
  export SENSU_SERVER_IP_ADDRESS=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
  # TODO: OpenStack could potential use a mounted drive for metadata instead of a service running at an IP address.
else
#if [ -z $IP_ADDRESS] ; then
  # Used when running the container on a workstation, not in a cloud.
  if [ -z $HOST_PUBLIC_IP_ADDRESS ] ; then
    export PUBLIC_IP_ADDRESS=$(ip addr show eth0 | grep "inet " | sed 's/.*inet \(.*\)\/.*/\1/g')
    export SENSU_SERVER_IP_ADDRESS=$PUBLIC_IP_ADDRESS
  else
    export PUBLIC_IP_ADDRESS=$HOST_PUBLIC_IP_ADDRESS
    export SENSU_SERVER_IP_ADDRESS=$HOST_PUBLIC_IP_ADDRESS
  fi
fi

echo "Public IP address: $PUBLIC_IP_ADDRESS"
echo "Sensu server IP addrss: $SENSU_SERVER_IP_ADDRESS"

# Update the params.json for youxia with the sensu server IP address for sensu and also for queueHost
sed -i.bak 's/\"SENSU_SERVER_IP_ADDRESS\": \"localhost\",/\"SENSU_SERVER_IP_ADDRESS\": \"'${SENSU_SERVER_IP_ADDRESS}'\",/g' ~/params.json
sed -i.bak 's/\"queueHost\": \"localhost\",/\"queueHost\": \"'${SENSU_SERVER_IP_ADDRESS}'\",/g' ~/params.json
sed -i.bak 's/\"FLEET_NAME\": \"fleet_name\",/\"FLEET_NAME\": \"'${FLEET_NAME}'\",/g' ~/params.json
sudo sed -i.bak 's/\"name\":.*sensu-server.*/\"name\":\"'${FLEET_NAME}'_sensu-server\",/g' /etc/sensu/conf.d/client.json
#Add the fleet name as the "managed tag" and slack namespace
sed -i.bak 's/managed_tag =.*/managed_tag = '${FLEET_NAME}'/g' ~/.youxia/config

# echo "Starting up Launcher services, starting with rabbitmq..."
sudo service rabbitmq-server start

echo "Adding rabbitmq users and vhosts..."
# rabbitmq users for arch3
sudo rabbitmqctl add_user queue_user queue
sudo rabbitmqctl set_permissions queue_user ".*" ".*" ".*"
sudo rabbitmqctl set_user_tags queue_user administrator
# rabbitmq users for youxia sensu
sudo rabbitmqctl add_vhost /sensu
sudo rabbitmqctl add_user sensu seqware
sudo rabbitmqctl set_user_tags sensu administrator
sudo rabbitmqctl set_permissions -p /sensu sensu ".*" ".*" ".*"
echo "Starting up redis, sensu, postgresql, and uchiwa..."
sudo service redis-server start
sudo service sensu-server start
sudo service sensu-api start
sudo service sensu-client start
sudo service postgresql start
sudo service uchiwa start

# Coordinator and Provisioner should already be running with the user logs in.
# But the system needs final configuration before starting the services.
pancancer sysconfig
pancancer coordinator start
# Maybe the Provisioner shouldn't be started until *after* the the first INI files have been generated and the job orders enqeueued...
#pancancer provisioner start

echo  "[END: $(date +%Y-%m-%d_%H:%M:%S)]"
exec 1>&3 2>&4

cat <<HELP_MESSAGE

**************************************
* Welcome to the Pancancer Launcher! *
**************************************

This docker container can be used to launch and control pancancer worker VMs.

The main command to interface with the pancancer components is "pancancer".

Use the command "pancancer -h" to get details on various pancancer commands.

HELP_MESSAGE
sleep 2
# Execute the argument passed in from the Dockerfile
# If no argument was passed in, then bash will be executed.
# I know this syntax is a little less common, read more about it here:
# http://wiki.bash-hackers.org/syntax/pe#use_a_default_value
CMD=${1-bash}
# shift will shift all arguments by 1, so *now* $1 is the first argument to the command that was earlier in $1
shift
$CMD $@
