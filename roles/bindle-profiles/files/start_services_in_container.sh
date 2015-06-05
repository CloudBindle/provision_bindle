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
#sudo service postgresql start
sudo service uchiwa start
# Copy pem keys and other config files from the host.
echo "Copying $PATH_TO_PEM to ~/.ssh/"
cp $PATH_TO_PEM ~/.ssh/
chmod 600 ~/.ssh/*

echo "Copying.aws credentials to ~/.aws"
cp /opt/from_host/aws/* ~/.aws/ 

if [ $HOST_ENV == "AWS" ] ; then
  echo "Querying AWS for public IP address of this machine..."
  export PUBLIC_IP_ADDRESS=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)
  export SENSU_SERVER_IP_ADDRESS=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
elif [ $HOST_ENV == 'OPENSTACK' ] ; then
  # Looks like the OpenStack metadata IP address is the same as AWS
  echo "Querying OpenStack for public IP address of this machine..."
  export PUBLIC_IP_ADDRESS=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)
  export SENSU_SERVER_IP_ADDRESS=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
else
#if [ -z $IP_ADDRESS] ; then
  # Used when running the container on a workstation, not in a cloud.
  export PUBLIC_IP_ADDRESS=$(ip addr show eth0 | grep "inet " | sed 's/.*inet \(.*\)\/.*/\1/g')
  export SENSU_SERVER_IP_ADDRESS=$PUBLIC_IP_ADDRESS
fi

echo "Public IP address: $PUBLIC_IP_ADDRESS"
echo "Sensu server IP addrss: $SENSU_SERVER_IP_ADDRESS"

# Execute the argument passed in from the Dockerfile
${1-bash}

