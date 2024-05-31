data "aws_ami" "bitnami_wordpress" {
  most_recent = true
  owners      = ["self", "amazon", "aws-marketplace"] # Adjust the owner accordingly

  filter {
    name   = "name"
    values = ["bitnami-wordpress-6.5.3-4-r04-linux-debian-12-x86_64-hvm-ebs-nami-*"]
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

# output "bitnami_wordpress_ami_id" {
#   value = data.aws_ami.bitnami_wordpress.id
# }