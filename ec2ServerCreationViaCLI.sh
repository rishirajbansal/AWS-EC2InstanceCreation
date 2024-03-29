#!/bin/bash -e
# EC2 Server Creation via CLI

AMIID="$(aws ec2 describe-images --filters "Name=name,Values=Amazon Linux AMI" --query "Images[0].ImageId" --output text)"

VPCID="$(aws ec2 describe-vpcs --filter "Name=isDefault, Values=true" --query "Vpcs[0].VpcId" --output text)"

SUBNETID="$(aws ec2 describe-subnets --filters "Name=vpc-id, Values=$VPCID" --query "Subnets[0].SubnetId" --output text)"

SGID="$(aws ec2 create-security-group --group-name WebSecurityGroup --description "1st Level Firewall" --vpc-id "$VPCID" --output text)"

aws ec2 authorize-security-group-ingress --group-id "$SGID" --protocol tcp --port 22 --cidr 0.0.0.0/0

INSTANCEID="$(aws ec2 run-instances --image-id "$AMIID" --key-name intel --instance-type t2.micro --security-group-ids "$SGID" --subnet-id "$SUBNETID" --query "Instances[0].InstanceId" --output text)"

echo "Retrieving $INSTANCEID ..."

aws ec2 wait instance-running --instance-ids "$INSTANCEID"

PUBLICNAME="$(aws ec2 describe-instances --instance-ids "$INSTANCEID" --query "Reservations[0].Instances[0].PublicDnsName" --output text)"

echo "$INSTANCEID is accepting SSH connections for $PUBLICNAME"

echo "ssh -i intel.pem ec2-ami@$PUBLICNAME"

read -r -p "Press [Enter] key to terminate $INSTANCEID ..."

aws ec2 terminate-instances --instance-ids "$INSTANCEID"

echo "Terminating $INSTANCEID ..."

aws ec2 wait instance-terminated --instance-ids "$INSTANCEID"

aws ec2 delete-security-group --group-id "$SGID"

echo "Finish"

