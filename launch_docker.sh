#! /usr/bin/bash
PEM_KEY=$1
# Create a folder that will be mounted into the docker container
[[ -d ~/ssh_for_docker ]] || mkdir ~/ssh_for_docker
# Copy the pem file in $1 to the folder for the container.
cp $PEM_KEY ~/ssh_for_docker/$(basename $PEM_KEY)
# After running this command, you will have to run "sudo docker attach launcher" to get into the container.
sudo docker run -i -t -d -P --privileged=true --name launcher -v /home/$USER/ssh_for_docker:/opt/ssh:ro seqware/launcher /bin/bash
# Once you are inside the container, you must copy /opt/ssh/$PEM_KEY to /home/ubuntu/.ssh and run "chmod og-r $PEM_KEY". Then it's business as usuall, for a Launcher node.
