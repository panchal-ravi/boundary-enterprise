variable "deployment_name" {
  type = string
}

variable "owner" {
  description = "Resource owner identified using an email address"
  type        = string
  default     = "rp"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = ""
}

variable "aws_vpc_cidr" {
  description = "AWS VPC CIDR"
  type        = string
  default     = "10.200.0.0/16"
}

variable "aws_private_subnets" {
  description = "AWS private subnets"
  type        = list(any)
  default     = ["10.200.20.0/24", "10.200.21.0/24", "10.200.22.0/24"]
}

variable "aws_private_subnets_eks" {
  description = "AWS private subnets"
  type        = list(any)
  default     = ["10.200.30.0/24", "10.200.31.0/24", "10.200.32.0/24"]
}


variable "aws_public_subnets" {
  description = "AWS public subnets"
  type        = list(any)
  default     = ["10.200.10.0/24", "10.200.11.0/24", "10.200.12.0/24"]
}

variable "aws_instance_type" {
  description = "AWS instance type"
  type        = string
  default     = "t3.micro"
}

variable "controller_count" {
  type    = number
  default = 1
}

variable "user_password" {
  type = string
}

variable "localhost" {
  type    = string
  default = "127.0.0.1"
}
/*
variable "rds_username" {
  type = string
}

variable "rds_password" {
  type = string
}
*/
variable "boundary_root_username" {
  type = string
}
variable "boundary_root_password" {
  type = string
}