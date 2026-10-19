#!/bin/bash
# Launch the ec2-cli instance without hard-coding the AMI or security group:
# both IDs are read from the running ec2-console instance (part 2).
# Run in the terminal on your computer: bash launch-ec2-cli.sh

set -euo pipefail

# Look up the AMI ID and security group ID of ec2-console
AMI=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=ec2-console" "Name=instance-state-name,Values=running" \
  --query 'Reservations[0].Instances[0].ImageId' --output text)
SG=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=ec2-console" "Name=instance-state-name,Values=running" \
  --query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId' --output text)

# --output text prints "None" when no instance matches the filters
if [ "$AMI" = "None" ] || [ "$SG" = "None" ]; then
  echo "No running instance named ec2-console found. Launch it in the AWS Console first." >&2
  exit 1
fi
echo "AMI: $AMI  Security group: $SG"

# Launch ec2-cli with the same AMI and security group
IID=$(aws ec2 run-instances \
  --image-id "$AMI" \
  --instance-type t3.micro \
  --key-name vockey \
  --security-group-ids "$SG" \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=ec2-cli}]' \
  --query 'Instances[0].InstanceId' --output text)
echo "Launched: $IID"

# Wait until it is running, then print its public IP
aws ec2 wait instance-running --instance-ids "$IID"
IP=$(aws ec2 describe-instances --instance-ids "$IID" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)

echo "Running at $IP. Connect with:"
echo "  ssh -i ~/.ssh/labsuser.pem ubuntu@$IP"
echo "Terminate with:"
echo "  aws ec2 terminate-instances --instance-ids $IID"
