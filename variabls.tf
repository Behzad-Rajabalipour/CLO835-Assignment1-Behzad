variable "region" {
  description = "The AWS region to deploy resources into"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr_block" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "availability_zone" {
  description = "Availability zone for the subnet"
  type        = string
  default     = "us-east-1a"
}

variable "instance_type" {
  description = "Instance type for the worker node"
  type        = string
  default     = "t2.micro"
}

variable "public_key" {
  description = "Instance type for the worker node"
  type        = string
  default     = "ec2_key"           # this key should exists in aws key pairs
}
