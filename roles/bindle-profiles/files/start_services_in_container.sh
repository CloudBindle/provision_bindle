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
echo "Starting up redis, sensu, and postgresql..."
sudo service redis-server start
sudo service sensu-server start
sudo service sensu-api start
sudo service postgresql start
# Copy pem keys and other config files from the host.
echo "Copying $PATH_TO_PEM to ~/.ssh/"
cp $PATH_TO_PEM ~/.ssh/
echo "Copying.aws credentials to ~/.aws"
cp /opt/from_host/aws/* ~/.aws/ 

# Execute the argument passed in from the Dockerfile
${1-bash}

