#! /usr/bin/bash

PEM_KEY=$1
IMAGE_VERSION=$2

# Create a folder that will be mounted into the docker container
[[ -d ~/ssh_for_docker ]] || mkdir ~/ssh_for_docker
# Copy the pem file in $1 to the folder for the container.
[[ -f ~/ssh_for_docker/$(basename $PEM_KEY) ]] || cp $PEM_KEY ~/ssh_for_docker/$(basename $PEM_KEY)
# After running this command, you will have to run "sudo docker attach launcher" to get into the container.
docker run -i -t -P --privileged=true --name pancancer_launcher \
        -v /home/$USER/ssh_for_docker:/opt/from_host/ssh:ro \
        -v /home/$USER/.aws/:/opt/from_host/aws:ro \
        -v /etc/localtime:/etc/localtime:ro \
        -p 15672:15672 \
        pancancer/pancancer_launcher:$IMAGE_VERSION /bin/bash
# Once you are inside the container, you must copy /opt/ssh/$PEM_KEY to /home/ubuntu/.ssh and run "chmod og-r $PEM_KEY". Also,
# be sure to copy your aws config files for youxia. Then it's business as usual, for a Launcher node.

