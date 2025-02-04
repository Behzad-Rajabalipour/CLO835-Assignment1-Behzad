#!/bin/bash

# Function to check and import IAM User
import_iam_user() {
  USER_NAME="ecr-access-user"
  if aws iam get-user --user-name $USER_NAME &> /dev/null; then
    echo "IAM User '$USER_NAME' exists. Importing into Terraform..."
    terraform import aws_iam_user.ecr_user $USER_NAME
  else
    echo "IAM User '$USER_NAME' does not exist. Terraform will create it."
  fi
}

# Function to check and import IAM Policy for user
import_iam_policy_USER() {
  POLICY_NAME="ecr-access-policy-all-repos"
  POLICY_ARN=$(aws iam list-policies --query "Policies[?PolicyName=='$POLICY_NAME'].Arn" --output text)
  
  if [ -n "$POLICY_ARN" ] && [ "$POLICY_ARN" != "None" ]; then
    echo "IAM Policy '$POLICY_NAME' exists. Importing into Terraform..."
    terraform import aws_iam_policy.ecr_access_policy $POLICY_ARN
  else
    echo "IAM Policy '$POLICY_NAME' does not exist. Terraform will create it."
  fi
}

# Function to check and import IAM Policy for EC2
import_iam_policy_EC2() {
  POLICY_NAME="ECRPullPolicy"
  POLICY_ARN=$(aws iam list-policies --query "Policies[?PolicyName=='$POLICY_NAME'].Arn" --output text)

  if [ -n "$POLICY_ARN" ] && [ "$POLICY_ARN" != "None" ]; then
    echo "IAM Policy '$POLICY_NAME' exists. Importing into Terraform..."
    terraform import aws_iam_policy.ecr_pull_policy $POLICY_ARN
  else
    echo "IAM Policy '$POLICY_NAME' does not exist. Terraform will create it."
  fi
}

# Function to check and import IAM Role
import_iam_role() {
  ROLE_NAME="EC2-ECR-Access-Role"
  if aws iam get-role --role-name $ROLE_NAME &> /dev/null; then
    echo "IAM Role '$ROLE_NAME' exists. Importing into Terraform..."
    terraform import aws_iam_role.ec2_ecr_role $ROLE_NAME
  else
    echo "IAM Role '$ROLE_NAME' does not exist. Terraform will create it."
  fi
}

# Function to check and import Instance Profile
import_instance_profile() {
  INSTANCE_PROFILE_NAME="EC2-ECR-Instance-Profile"
  if aws iam get-instance-profile --instance-profile-name $INSTANCE_PROFILE_NAME &> /dev/null; then
    echo "Instance Profile '$INSTANCE_PROFILE_NAME' exists. Importing into Terraform..."
    terraform import aws_iam_instance_profile.ec2_ecr_profile $INSTANCE_PROFILE_NAME
  else
    echo "Instance Profile '$INSTANCE_PROFILE_NAME' does not exist. Terraform will create it."
  fi
}

# Function to check and import EC2 VPC
import_vpc() {
  VPC_NAME="main-vpc"
  VPC_ID=$(aws ec2 describe-vpcs --query "Vpcs[?Tags[?Key=='Name' && Value=='$VPC_NAME']].VpcId" --output text)
  
  echo "VPC_ID: $VPC_ID"

  # If no VPC ID was returned, output a message
  if [ "$VPC_ID" == "None" ] || [ -z "$VPC_ID" ] || [ "$VPC_ID" == "[]" ]; then
    echo "VPC '$VPC_NAME' does not exist or was not found. Terraform will create it."
  else
    echo "VPC '$VPC_NAME' exists. Importing into Terraform..."
    terraform import aws_vpc.main_vpc "$VPC_ID"
  fi
}

# Function to check and import IAM Access Key
import_iam_access_key() {
  USER_NAME="ecr-access-user"
  ACCESS_KEYS=$(aws iam list-access-keys --user-name $USER_NAME --query "AccessKeyMetadata[*].AccessKeyId" --output text)

  if [ $(echo "$ACCESS_KEYS" | wc -w) -ge 2 ]; then
    echo "User '$USER_NAME' already has 2 access keys. Deleting an old key before creating a new one..."
    # Optionally delete an old access key
    OLD_KEY=$(echo "$ACCESS_KEYS" | awk '{print $1}')
    aws iam delete-access-key --user-name $USER_NAME --access-key-id $OLD_KEY
  fi
}

# Function to check and import EC2 Subnet
import_subnet() {
  SUBNET_NAME="public-subnet"
  SUBNET_ID=$(aws ec2 describe-subnets --query "Subnets[?Tags[?Key=='Name' && Value=='$SUBNET_NAME']].SubnetId" --output text)

  if [ -n "$SUBNET_ID" ] && [ "$SUBNET_ID" != "None" ]; then
    echo "Subnet '$SUBNET_NAME' exists. Importing into Terraform..."
    terraform import aws_subnet.public_subnet $SUBNET_ID
  else
    echo "Subnet '$SUBNET_NAME' does not exist. Terraform will create it."
  fi
}

# Function to check and import EC2 Internet Gateway
import_internet_gateway() {
  IGW_NAME="main-igw"
  IGW_ID=$(aws ec2 describe-internet-gateways --query "InternetGateways[?Tags[?Key=='Name' && Value=='$IGW_NAME']].InternetGatewayId" --output text)

  if [ -n "$IGW_ID" ] && [ "$IGW_ID" != "None" ]; then
    echo "Internet Gateway '$IGW_NAME' exists. Importing into Terraform..."
    terraform import aws_internet_gateway.main_igw $IGW_ID
  else
    echo "Internet Gateway '$IGW_NAME' does not exist. Terraform will create it."
  fi
}

# Function to check and import EC2 Route Table Association
import_route_table_association() {
  ROUTE_TABLE_NAME="main-route-table"
  ROUTE_TABLE_ID=$(aws ec2 describe-route-tables --query "RouteTables[?Tags[?Key=='Name' && Value=='$ROUTE_TABLE_NAME']].RouteTableId" --output text)

  if [ -n "$ROUTE_TABLE_ID" ] && [ "$ROUTE_TABLE_ID" != "None" ]; then
    echo "Route Table '$ROUTE_TABLE_NAME' exists. Checking for association..."
    ASSOCIATION_ID=$(aws ec2 describe-route-tables --route-table-id $ROUTE_TABLE_ID --query "RouteTables[0].Associations[0].RouteTableAssociationId" --output text)
    
    if [ -n "$ASSOCIATION_ID" ] && [ "$ASSOCIATION_ID" != "None" ]; then
      echo "Route Table '$ROUTE_TABLE_NAME' already has an association. Importing into Terraform..."
      terraform import aws_route_table_association.subnet_association $ROUTE_TABLE_ID
    else
      echo "No existing association found. erraform will create it."
    fi
  else
    echo "Route Table '$ROUTE_TABLE_NAME' does not exist. Terraform will create it."
  fi
}

# Function to check and import EC2 Security Group
import_security_group() {
  SG_NAME="worker-node-sg"
  SG_ID=$(aws ec2 describe-security-groups --query "SecurityGroups[?GroupName=='$SG_NAME'].GroupId" --output text)

  if [ -n "$SG_ID" ] && [ "$SG_ID" != "None" ]; then
    echo "Security Group '$SG_NAME' already exists. Importing into Terraform..."
    terraform import aws_security_group.worker_node_sg $SG_ID
  else
    echo "Security Group '$SG_NAME' does not exist. Terraform will create it."
  fi
}

# Execute Functions
import_iam_user
import_iam_policy_USER
import_iam_policy_EC2
import_iam_role
import_instance_profile
import_vpc
import_iam_access_key
import_subnet
import_internet_gateway
import_route_table_association
import_security_group
