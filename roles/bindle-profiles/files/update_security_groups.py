#! /usr/bin/python
"This script will update AWS EC2 security groups"

# This script needs to be run with python 2.7, because of boto3
import boto3
#import requests
import sys

# get instance ID with: `curl http://169.254.169.254/latest/meta-data/instance-id`
# get public IP with: `curl http://169.254.169.254/latest/meta-data/public-ipv4`


#request = requests.get('http://169.254.169.254/latest/meta-data/instance-id')
#instanceID = request.text
instanceID = sys.argv[1]
# print(instanceID)

#request = requests.get('http://169.254.169.254/latest/meta-data/public-ipv4')
#publicIPAddress = request.text
publicIPAddress = sys.argv[2]
# print(publicIPAddress)

ec2 = boto3.resource('ec2')
instance = ec2.Instance(instanceID)

# For each security group that this instance belongs to, add an inbound rule for all TCP traffic from this public IP address.
for security_group in instance.security_groups:
    ec2_security_group = ec2.SecurityGroup(security_group['GroupId'])
    #print(security_group)
    print('updating security group: ' + security_group['GroupName'])

    # Need a rule for the public IP address of the Pancancer Launcher
    try:
        ec2_security_group.authorize_ingress(DryRun=False, IpProtocol='tcp', FromPort=0, ToPort=65535, CidrIp=publicIPAddress + '/32')
    except Exception as e:
        print(e)

    # Also need a rule for all members of this group, so that workers can talk back to launcher.
    try:
        ec2_security_group.authorize_ingress(DryRun=False, IpPermissions=[
                                   {'IpProtocol':'tcp',
                                    'FromPort':0,
                                    'ToPort':65535,
                                    'UserIdGroupPairs':[
                                       {'GroupName':security_group['GroupName']}
                                      ]
                                    }
                                 ])
    except Exception as e:
        print(e)
