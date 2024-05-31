resource "aws_security_group" "rds_sg" {
  name_prefix = "rds-sg"
  description = "Security group for RDS Aurora Serverless"
  vpc_id      = aws_vpc.vpc.id
}

resource "aws_security_group_rule" "rds_ingress" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds_sg.id
  source_security_group_id = aws_security_group.asg_security_group.id
}
module "aurora_mysql_v2" {
  source            = "terraform-aws-modules/rds-aurora/aws"
  version           = "9.4.0"
  name              = "${var.env}-mysqlv2"
  engine            = "aurora-mysql"
  engine_mode       = "provisioned"
  engine_version    = "8.0"
  storage_encrypted = true
  master_username   = "root"

  vpc_id                 = aws_vpc.vpc.id
  create_db_subnet_group = true
  subnets                = [for i in aws_subnet.private_subnet : i.id]
  db_subnet_group_name   = "${var.env}-subnet-grp"
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  create_security_group  = false
  deletion_protection    = true
  monitoring_interval    = 60

  apply_immediately   = true
  skip_final_snapshot = true

  serverlessv2_scaling_configuration = {
    min_capacity = 1
    max_capacity = 10
  }

  instance_class = "db.serverless"
  instances = {
    one = {}
  }


}


resource "random_password" "master" {
  length  = 20
  special = false
}