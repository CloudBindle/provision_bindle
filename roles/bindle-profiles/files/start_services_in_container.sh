#! /bin/bash

# Converting this to ansible to simplify container setup with docker compose
echo "Starting up launcher services ..."
ansible-playbook /docker-start.yml -c local

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

