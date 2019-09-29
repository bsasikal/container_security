//Global variables
variable "region" {
  description = "AWS region"
  default = "us-west-2"
}

variable "shared_credentials_file" {
  description = "AWS credentials file path"
  default = "/Users/Sasi/.aws/credentials"
}

variable "aws_profile" {
  description = "AWS profile"
  default = "default"
}

variable "availability_zones" {
  type        = "list"
  description = "List of Availability Zones"
  default = ["us-west-2a", "us-west-2b"]
}

// Default variables
variable "vpc_name" {
  description = "VPC name"
  default     = "demo"
}

variable "cidr_block" {
  description = "VPC CIDR block"
  default     = "10.0.0.0/16"
}

variable "public_count" {
  default     = 1
  description = "Number of public subnets"
}

variable "private_count" {
  default     = 2
  description = "Number of private subnets"
}

variable "public_key" {
  description = "SSH public key"
  default = "/Users/sasi/.ssh/id_rsa.pub"
}

variable "instance_type" {
  default     = "t2.micro"
  description = "EC2 instance type"
}

variable "jenkins_master_instance_type" {
  description = "Jenkins Master instance type"
  default     = "t2.large"
}

variable "key_name" {
  description = "SSH KeyPair"
  default = "demo"
}

variable "jenkins_username" {
  description = "Jenkin login username"
  default = "admin"
}

variable "jenkins_password" {
  description = "Jenkins login password"
  default = "admin"
}

variable "jenkins_credentials_id" {
  description = "Jenkins credentials id"
  default = "jenkins-slaves"
}

// We will be running anchore engine locally on the agents which is CPU and memory heavy
variable "jenkins_slave_instance_type" {
  description = "Jenkins Slave instance type"
  default     = "t2.xlarge"
}

//SNS
variable "display_name" {
  type        = "string"
  description = "Insight Build Admin"
  default = "Insight Build Admin"
}
variable "email_addresses" {
  type        = "list"
  description = "bsasikal2000@gmail.com"
  default = ["bsasikal2000@gmail.com"]
}
variable "protocol" {
  default     = "email"
  description = "SNS Protocol to use. email or email-json"
  type        = "string"
}
variable "stack_name" {
  type        = "string"
  description = "Scanner Vulnerability"
  default = "scanner-vulnerability"
}