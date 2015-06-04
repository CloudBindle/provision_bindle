#! /usr/bin/bash

PEM_KEY=$1
IMAGE_VERSION=$2
HOST_ENV=$3
if [ -z $HOST_ENV ] ; then
  HOST_ENV="AWS"
fi

#TODO: Need a generic solution that will also work for OpenStack, localhost, etc...
#if [ $HOST_ENV == "AWS" ] ; then
#  echo "Querying AWS for public IP address of this machine..."
#  IP_ADDRESS=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)
#else
#if [ -z $IP_ADDRESS] ; then
#  IP_ADDRESS=$(ip addr show eth0 | grep "inet " | sed 's/.*inet \(.*\)\/.*/\1/g')
#fi
# Create a folder that will be mounted into the docker container
[[ -d ~/pancancer_launcher_ssh ]] || mkdir ~/pancancer_launcher_ssh
# Create a config folder if there isn't one already.
[[ -d ~/pancancer_launcher_config ]] || mkdir ~/pancancer_launcher_config
# create the ~/.aws folder, if it doesn't already exist
[[ -d ~/.aws/ ]] || mkdir ~/.aws

# Make the host machine a sensu-host for the container. This will only work if you specify "--net=host"
# in the docker run command. And you can't do it INSIDE the container because docker will not let you
# modify /etc/hosts
# On second thought, this seems to confuse rabbitmq - maybe we shouldn't do this...
#sudo echo "127.0.0.1 sensu-server" >> /etc/hosts

# Copy the pem file in $1 to the folder for the container.
PEM_KEY_BASENAME=$(basename $PEM_KEY)
[[ -f ~/ssh_for_docker/$PEM_KEY_BASENAME ]] || cp $PEM_KEY ~/ssh_for_docker/$PEM_KEY_BASENAME
# After running this command, you will have to run "sudo docker attach launcher" to get into the container.
docker run -i -t -P --privileged=true --name pancancer_launcher \
        -v /home/$USER/pancancer_launcher_config:/opt/from_host/config:ro \
        -v /home/$USER/ssh_for_docker:/opt/from_host/ssh:ro \
        -v /home/$USER/.aws/:/opt/from_host/aws:ro \
        -v /etc/localtime:/etc/localtime:ro \
        -p 15672:15672 \
        -p 5671:5671 \
        -p 4567:4567 \
        -p 8080:8080 \
        -p 3000:3000 \
        -e "HOST_ENV=$HOST_ENV" \
        -e "PATH_TO_PEM=/opt/from_host/ssh/$PEM_KEY_BASENAME" \
        --add-host sensu-server:127.0.0.1 \
        pancancer/pancancer_launcher:$IMAGE_VERSION /bin/bash /home/ubuntu/start_services_in_container.sh /bin/bash 
# Once you are inside the container, you must copy /opt/ssh/$PEM_KEY to /home/ubuntu/.ssh and run "chmod og-r $PEM_KEY". Also,
# be sure to copy your aws config files for youxia. Then it's business as usual, for a Launcher node.


