#! /bin/bash

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
elif [ "$HOST_ENV" == "OPENSTACK" ] ; then
  # Looks like the OpenStack metadata IP address is the same as AWS
  echo "Querying OpenStack for public IP address of this machine..."
  export PUBLIC_IP_ADDRESS=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)
  export SENSU_SERVER_IP_ADDRESS=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
  # TODO: OpenStack could potential use a mounted drive for metadata instead of a service running at an IP address.
else
#if [ -z $IP_ADDRESS] ; then
  # Used when running the container on a workstation, not in a cloud.
  export PUBLIC_IP_ADDRESS=$(ip addr show eth0 | grep "inet " | sed 's/.*inet \(.*\)\/.*/\1/g')
  export SENSU_SERVER_IP_ADDRESS=$PUBLIC_IP_ADDRESS
fi

echo "Public IP address: $PUBLIC_IP_ADDRESS"
echo "Sensu server IP addrss: $SENSU_SERVER_IP_ADDRESS"

# Update the params.json for youxia with the sensu server IP address
sed -i.bak 's/\"SENSU_SERVER_IP_ADDRESS\": \"localhost\",/\"SENSU_SERVER_IP_ADDRESS\": \"'${SENSU_SERVER_IP_ADDRESS}'\"/g' ~/params.json

# Execute the argument passed in from the Dockerfile
# If no argument was passed in, then bash will be executed.
# I know this syntax is a little less common, read more about it here:
# http://wiki.bash-hackers.org/syntax/pe#use_a_default_value
CMD=${1-bash}
# shift will shift all arguments by 1, so *now* $1 is the first argument to the command that was earlier in $1
shift
$CMD $@

