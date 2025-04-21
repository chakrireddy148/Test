#!/bin/bash

# Exit on any error
set -e

# Prompt the user for basic input
read -p "Enter the EC2 instance name: " INSTANCE_NAME
read -p "Enter the AWS region (e.g., us-east-1): " REGION
read -p "Enter the AMI ID (e.g., ami-0c55b159cbfafe1f0): " AMI_ID
read -p "Enter the Instance Type (e.g., t2.micro): " INSTANCE_TYPE
read -p "Enter the Key Pair Name (already created in AWS): " KEY_NAME
read -p "Enter the Security Group ID (e.g., sg-0123456789abcdef0): " SECURITY_GROUP_ID
read -p "Enter the Subnet ID (optional, press Enter to skip): " SUBNET_ID

# Optional subnet param
if [ -z "$SUBNET_ID" ]; then
    SUBNET_PARAM=""
else
    SUBNET_PARAM="--subnet-id $SUBNET_ID"
fi

# Launch the instance
echo "Creating EC2 instance..."
INSTANCE_ID=$(aws ec2 run-instances \
    --region "$REGION" \
    --image-id "$AMI_ID" \
    --count 1 \
    --instance-type "$INSTANCE_TYPE" \
    --key-name "$KEY_NAME" \
    --security-group-ids "$SECURITY_GROUP_ID" \
    $SUBNET_PARAM \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME}]" \
    --query "Instances[0].InstanceId" \
    --output text)

echo "Instance created with ID: $INSTANCE_ID"

# Wait until it's running
echo "Waiting for the instance to enter the 'running' state..."
aws ec2 wait instance-running --region "$REGION" --instance-ids "$INSTANCE_ID"
echo "Instance is now running."

# Get public IP
PUBLIC_IP=$(aws ec2 describe-instances \
    --region "$REGION" \
    --instance-ids "$INSTANCE_ID" \
    --query "Reservations[0].Instances[0].PublicIpAddress" \
    --output text)

echo "EC2 instance '$INSTANCE_NAME' is ready!"
echo "Public IP: $PUBLIC_IP"
