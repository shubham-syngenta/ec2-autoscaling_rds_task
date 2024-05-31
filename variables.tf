
# variable "ami" {
#   description = "ami of ec2 instance"
#   type        = string
# }


variable "instance_type" {
  description = "launch template EC2 instance type"
  type        = string
  default     = "t2.micro"
}


variable "ec2_user_data" {
  description = "variable indicates that the script configures Apache on a server"
  type        = string
  default     = <<EOF
#!/bin/bash
# Install Apache on Ubuntu
sudo apt update -y
sudo apt install -y apache2
sudo cat > /var/www/html/index.html << EOF
<html>
<head>
  <title> Apache 2023 Terraform </title>
</head>
<body>
  <p> Welcome to Jason's Online-Store powered by AWS EC2 Auto-Scaling Group using Terraform!
</body>
</html>
EOF
}



variable "vpc_cidr" {
  description = "VPC cidr block"
  type        = string
  default     = "10.10.0.0/16"
}

#These Public subnets are used for resources that need to be accessible from the internet
variable "public_subnet_cidr" {
  description = "Public Subnet cidr block"
  type        = list(string)
  default     = ["10.10.0.0/24", "10.10.2.0/24"]
}

#These Private subnets can be used to deploy resources that do not need to be accessible from the internet.
variable "private_subnet_cidr" {
  description = "Private Subnet cidr block"
  type        = list(string)
  default     = ["10.10.3.0/24", "10.10.4.0/24"]
}

#This is a Environement variable 
variable "env" {
  description = "Environment name for deployment"
  type        = string
}

# This is a Region Variable
variable "aws_region" {
  description = "AWS region name"
  type        = string
  default     = "us-east-1"
}


variable "domain_name" {}
