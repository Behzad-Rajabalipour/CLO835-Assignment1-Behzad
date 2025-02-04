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
  
  if [ -n "$POLICY_ARN" ]; then
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

  if [ -n "$POLICY_ARN" ]; then
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
  VPC_NAME="my-vpc"
  VPC_ID=$(aws ec2 describe-vpcs --query "Vpcs[?Tags[?Key=='Name' && Value=='$VPC_NAME']].VpcId" --output text)
  
  if [ "$VPC_ID" != "None" ]; then
    echo "VPC '$VPC_NAME' exists. Importing into Terraform..."
    terraform import aws_vpc.main_vpc $VPC_ID
  else
    echo "VPC '$VPC_NAME' does not exist. Terraform will create it."
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

# Execute Functions
import_iam_user
import_iam_policy_USER
import_iam_policy_EC2
import_iam_role
import_instance_profile
import_vpc
import_iam_access_key
