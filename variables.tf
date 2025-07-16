variable "vpc_name" {
  description = "The name of the VPC."
  type        = string
}

variable "aws_region" {
  description = "The AWS region to deploy the resources."
  type        = string
  default     = "ap-southeast-2"
}

variable "sns_topic_arn" {
  description = "The ARN of the SNS topic for notifications."
  type        = string
}
