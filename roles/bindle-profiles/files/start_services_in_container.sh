#! /bin/bash

echo "Starting up Launcher services..."
sudo service rabbitmq-server start
# add rabbit mq usrs and vhosts

sudo service redis-server start
sudo service sensu-server start
sudo service sensi-api start
sudo service postgresql start

