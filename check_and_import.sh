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

# Function to check and import IAM Policy
import_iam_policy() {
  POLICY_NAME="ecr-access-policy-all-repos"
  POLICY_ARN=$(aws iam list-policies --query "Policies[?PolicyName=='$POLICY_NAME'].Arn" --output text)
  
  if [ -n "$POLICY_ARN" ]; then
    echo "IAM Policy '$POLICY_NAME' exists. Importing into Terraform..."
    terraform import aws_iam_policy.ecr_access_policy $POLICY_ARN
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

# Execute Functions
import_iam_user
import_iam_policy
import_iam_role
import_instance_profile
