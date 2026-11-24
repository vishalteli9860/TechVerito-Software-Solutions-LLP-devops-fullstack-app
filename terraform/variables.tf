variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Name prefix for AWS resources"
  type        = string
  default     = "techverito"
}

variable "key_pair_name" {
  description = "Name of an existing EC2 key pair"
  type        = string
}

variable "allowed_ssh_cidrs" {
  description = "CIDRs allowed to SSH and access Jenkins"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "instance_type" {
  description = "EC2 instance type; t3.small is a minimum practical size"
  type        = string
  default     = "t3.small"
}
