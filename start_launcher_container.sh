#! /usr/bin/bash

PEM_KEY=$1
IMAGE_VERSION=$2
HOST_ENV=$3
if [ -z $HOST_ENV ] ; then
  HOST_ENV="AWS"
fi

#TODO: Need a generic solution that will also work for OpenStack, localhost, etc...
if [ $HOST_ENV == "AWS" ] ; then 
  IP_ADDRESS=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)
else
#if [ -z $IP_ADDRESS] ; then
  IP_ADDRESS=$(ip addr show eth0 | grep "inet " | sed 's/.*inet \(.*\)\/.*/\1/g')
fi
# Create a folder that will be mounted into the docker container
[[ -d ~/ssh_for_docker ]] || mkdir ~/ssh_for_docker
# Copy the pem file in $1 to the folder for the container.
PEM_KEY_BASENAME=$(basename $PEM_KEY)
[[ -f ~/ssh_for_docker/$PEM_KEY_BASENAME ]] || cp $PEM_KEY ~/ssh_for_docker/$PEM_KEY_BASENAME
# After running this command, you will have to run "sudo docker attach launcher" to get into the container.
docker run -i -t -P --privileged=true --name pancancer_launcher \
        -v /home/$USER/for_pancancer_launcher_container:/opt/from_host/misc:ro \
        -v /home/$USER/ssh_for_docker:/opt/from_host/ssh:ro \
        -v /home/$USER/.aws/:/opt/from_host/aws:ro \
        -v /etc/localtime:/etc/localtime:ro \
        -p 15672:15672 \
        -p 5672:5672 \
        -p 4567:4567 \
        -p 8080:8080 \
        -e "PUBLIC_IP_ADDRESS=$IP_ADDRESS" \
        -e "PATH_TO_PEM=/opt/from_host/ssh/$PEM_KEY_BASENAME" \
        pancancer/pancancer_launcher:$IMAGE_VERSION /bin/bash
# Once you are inside the container, you must copy /opt/ssh/$PEM_KEY to /home/ubuntu/.ssh and run "chmod og-r $PEM_KEY". Also,
# be sure to copy your aws config files for youxia. Then it's business as usual, for a Launcher node.


