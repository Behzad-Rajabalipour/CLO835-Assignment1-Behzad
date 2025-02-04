provider "aws" {
  region = var.region
}

# Data source for AMI id
data "aws_ami" "latest_amazon_linux" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Create a VPC
resource "aws_vpc" "main_vpc" {
  cidr_block = var.vpc_cidr_block
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "main-vpc"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "main-igw"
  }
}

# Create a Route Table
resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "main-route-table"
  }
}

# Create a Route for the Internet Gateway
resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# Create a Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.public_subnet_cidr_block
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet"
  }
}

# Associate the Route Table with the Public Subnet
resource "aws_route_table_association" "subnet_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.route_table.id
}

#-----------------------------------------------
# This is used to get the current user account ID 
data "aws_caller_identity" "current" {}

# IAM User for ECR Access
resource "aws_iam_user" "ecr_user" {
  name = "ecr-access-user"
}

# IAM Policy Document for ECR Access (all repositories)
data "aws_iam_policy_document" "ecr_policy" {

  statement {
    effect    = "Allow"
    actions   = [
      "ecr:GetDownloadUrlForLayer", 
      "ecr:BatchGetImage", 
      "ecr:BatchCheckLayerAvailability", 
      "ecr:InitiateLayerUpload", 
      "ecr:UploadLayerPart", 
      "ecr:PutImage"
    ]
    resources = ["arn:aws:ecr:${var.region}:${data.aws_caller_identity.current.account_id}:repository/*"]
  }

  statement {
    effect  = "Allow"
    actions = [
      "ecr:ListImages", 
      "ecr:DescribeImages", 
      "ecr:DescribeRepositories", 
      "ecr:GetRepositoryPolicy", 
      "ecr:CreateRepository", 
      "ecr:DeleteRepository", 
      "ecr:TagResource", 
      "ecr:UntagResource", 
      "ecr:PutRepositoryPolicy", 
      "ecr:GetLifecyclePolicy", 
      "ecr:PutLifecyclePolicy", 
      "ecr:CompleteLayerUpload", 
      "ecr:DescribeImageScanFindings"
    ]
    resources = ["arn:aws:ecr:${var.region}:${data.aws_caller_identity.current.account_id}:repository/*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
}

# IAM Policy for ECR Access
resource "aws_iam_policy" "ecr_access_policy" {
  name        = "ecr-access-policy-all-repos"
  description = "ECR access policy for all repositories"
  policy      = data.aws_iam_policy_document.ecr_policy.json
}

# Attach IAM Policy to the User
resource "aws_iam_user_policy_attachment" "ecr_user_policy" {
  user       = aws_iam_user.ecr_user.name
  policy_arn = aws_iam_policy.ecr_access_policy.arn
}

# IAM Access Key for the ECR User
resource "aws_iam_access_key" "ecr_user_key" {
  user = aws_iam_user.ecr_user.name
}

#-------------------------------------
# Create an IAM Role for EC2
resource "aws_iam_role" "ec2_ecr_role" {
  name = "EC2-ECR-Access-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# Attach an IAM Policy to allow EC2 to pull images from ECR
resource "aws_iam_policy" "ecr_pull_policy" {
  name        = "ECRPullPolicy"
  description = "Allows EC2 instances to pull images from ECR"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage"
      ]
      Resource = "*"
    }]
  })
}

# Attach the policy to the IAM Role
resource "aws_iam_role_policy_attachment" "ecr_role_attach" {
  role       = aws_iam_role.ec2_ecr_role.name
  policy_arn = aws_iam_policy.ecr_pull_policy.arn
}

# Create an Instance Profile
resource "aws_iam_instance_profile" "ec2_ecr_profile" {
  name = "EC2-ECR-Instance-Profile"
  role = aws_iam_role.ec2_ecr_role.name
}

#----------------------------------------------
# Create a Security Group for the EC2 instance
resource "aws_security_group" "worker_node_sg" {
  name        = "worker-node-sg"
  description = "Security group for EC2 instance with open ports 8081, 8082, 8083, and 22"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow all inbound traffic on port 8081
  }

  ingress {
    from_port   = 8082
    to_port     = 8082
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow all inbound traffic on port 8082
  }

  ingress {
    from_port   = 8083
    to_port     = 8083
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow all inbound traffic on port 8083
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow SSH access on port 22
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "worker-node-sg"
  }
}

# # Reference the key pair created by Boto3
# resource "aws_key_pair" "my_key_pair" {
#   key_name   = "ec2_key"
#   public_key = file("~/.ssh/ec2_key.pub")  # Path to your public key (if available)
# }

# EC2 Instance with the created key pair
resource "aws_instance" "worker_node" {
  ami                    = data.aws_ami.latest_amazon_linux.id
  instance_type          = var.instance_type
  key_name               = var.public_key  # make sure this public key exists in aws key pairs
  subnet_id              = aws_subnet.public_subnet.id  # Use the public subnet ID created above
  security_groups        = [aws_security_group.worker_node_sg.id]
  associate_public_ip_address = true

  iam_instance_profile   = aws_iam_instance_profile.ec2_ecr_profile.name  # Attach IAM role

  tags = {
    Name = "WorkerNode"
  }
}