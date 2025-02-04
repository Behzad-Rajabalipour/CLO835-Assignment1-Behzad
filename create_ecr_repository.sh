#!/bin/bash

set -e

# Ensure ECR_REPO_NAME is set
if [[ -z "$ECR_REPO_NAME" ]]; then
  echo "Error: ECR_REPO_NAME is not set."
  exit 1
fi

# Set AWS region (default: us-east-1)
AWS_REGION="${AWS_REGION:-us-east-1}"

# Check if the ECR repository exists
if aws ecr describe-repositories --repository-names "$ECR_REPO_NAME" --region "$AWS_REGION" >/dev/null 2>&1; then
  echo "ECR repository '$ECR_REPO_NAME' already exists in region '$AWS_REGION'."
else
  echo "Creating ECR repository: '$ECR_REPO_NAME' in region '$AWS_REGION'..."
  aws ecr create-repository --repository-name "$ECR_REPO_NAME" --region "$AWS_REGION"
  echo "ECR repository '$ECR_REPO_NAME' created successfully."
fi
