instance_type       = "t2.micro"
vpc_cidr            = "10.10.0.0/16"
public_subnet_cidr  = ["10.10.2.0/24", "10.10.3.0/24"]
private_subnet_cidr = ["10.10.4.0/24", "10.10.5.0/24"]
env                 = "demo"
domain_name         = "assignment.syt.dev"