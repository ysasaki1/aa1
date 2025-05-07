# Variable definitions with types

variable "imageid" {
  description = "The ID of the AMI to use for the instance"
  type        = string
}

variable "instance-type" {
  description = "The type of instance to create"
  type        = string
}

variable "key-name" {
  description = "The name of the key pair to use for SSH access"
  type        = string
}

variable "vpc_security_group_ids" {
  description = "List of VPC security group IDs to associate with the instance"
  type        = list(string)
}

variable "cnt" {
  description = "Count of instances to create"
  type        = number
}

variable "az" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-2a", "us-east-2b", "us-east-2c"]
}

variable "tag-name" {
  description = "The tag name for resources"
  type        = string
}

variable "raw-bucket" {
  description = "Name of the raw S3 bucket"
  type        = string
}

variable "finished-bucket" {
  description = "Name of the finished S3 bucket"
  type        = string
}

variable "sns-topic" {
  description = "Name of the SNS topic"
  type        = string
}

variable "sqs" {
  description = "Name of the SQS queue"
  type        = string
}

variable "dbname" {
  description = "Name of the RDS database"
  type        = string
}

variable "uname" {
  description = "Username for the RDS database"
  type        = string
}

variable "pass" {
  description = "Password for the RDS database"
  type        = string
}

variable "elb-name" {
  description = "Name of the Elastic Load Balancer"
  type        = string
}

variable "asg-name" {
  description = "Name of the Auto Scaling Group"
  type        = string
}

variable "min" {
  description = "Minimum number of instances in the Auto Scaling Group"
  type        = number
}

variable "max" {
  description = "Maximum number of instances in the Auto Scaling Group"
  type        = number
}

variable "desired" {
  description = "Desired number of instances in the Auto Scaling Group"
  type        = number
}

variable "tg-name" {
  description = "Name of the Load Balancer Target Group"
  type        = string
}
