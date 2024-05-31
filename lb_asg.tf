resource "aws_security_group" "alb_security_group" {
  name        = "${var.env}-alb-security-group"
  description = "ALB Security Group"
  vpc_id      = aws_vpc.vpc.id

  # Define HTTP ingress rule
  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Define HTTPS ingress rule
  ingress {
    description = "HTTPS from Internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.env}-alb-security-group"
  }
}
resource "aws_security_group" "asg_security_group" {
  name        = "${var.env}-asg-security-group"
  description = "ASG Security Group"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_security_group.id]
  }

  ingress {
    description     = "HTTPS from ALB"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_security_group.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.env}-asg-security-group"
  }
}

resource "aws_lb" "alb" {
  name               = "${var.env}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_security_group.id]
  subnets            = [for i in aws_subnet.public_subnet : i.id]
}

resource "aws_lb_target_group" "target_group" {
  name     = "${var.env}-tgrp"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id
  health_check {
    path    = "/"
    matcher = 200
  }
}


resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
  tags = {
    Name = "${var.env}-alb-listenter"
  }
}
resource "aws_lb_target_group" "https_target_group" {
  name     = "${var.env}-tgrp-https"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = aws_vpc.vpc.id
  health_check {
    path    = "/"
    matcher = 200
  }
}

resource "aws_lb_listener" "alb_https_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.acm-certificate.arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.https_target_group.arn
  }
  tags = {
    Name = "${var.env}-alb-https-listener"
  }
}

resource "aws_launch_template" "launch_template" {
  name          = "${var.env}-launch-template"
  image_id      = data.aws_ami.bitnami_wordpress.id
  instance_type = var.instance_type
  iam_instance_profile {
    arn = aws_iam_instance_profile.ssm_instance_profile.arn
  }
  network_interfaces {
    device_index    = 0
    security_groups = [aws_security_group.asg_security_group.id]
  }
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.env}-asg-ec2"
    }
  }
  # user_data = base64encode("${var.ec2_user_data}")
}

resource "aws_autoscaling_group" "auto_scaling_group" {
  name             = "my-autoscaling-group"
  desired_capacity = 1
  max_size         = 5
  min_size         = 1
  vpc_zone_identifier = flatten([
    aws_subnet.private_subnet.*.id,
  ])
  target_group_arns = [
    aws_lb_target_group.target_group.arn,
    aws_lb_target_group.https_target_group.arn
  ]
  launch_template {
    id      = aws_launch_template.launch_template.id
    version = aws_launch_template.launch_template.latest_version
  }
}

resource "aws_autoscaling_policy" "cpu_utilization_scaling_policy" {
  name = "cpu-utilization-scaling-policy"
  #   scaling_adjustment     = 1  # Increase by 1 instance
  adjustment_type = "ChangeInCapacity"
  #   cooldown               = 300  # 5 minutes cooldown period
  policy_type               = "TargetTrackingScaling"
  estimated_instance_warmup = 300 # 5 minutes warm-up time
  autoscaling_group_name    = aws_autoscaling_group.auto_scaling_group.name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 40 # Scale out when CPU utilization is above 50%
  }
}


resource "aws_autoscaling_policy" "example" {
  autoscaling_group_name = aws_autoscaling_group.auto_scaling_group.name
  name                   = aws_autoscaling_group.auto_scaling_group.name
  policy_type            = "PredictiveScaling"
  predictive_scaling_configuration {
    metric_specification {
      target_value = 10
      predefined_load_metric_specification {
        predefined_metric_type = "ASGTotalCPUUtilization"
        resource_label         = "demo"
      }
      customized_scaling_metric_specification {
        metric_data_queries {
          id = "scaling"
          metric_stat {
            metric {
              metric_name = "CPUUtilization"
              namespace   = "AWS/EC2"
              dimensions {
                name  = "AutoScalingGroupName"
                value = "my-test-asg"
              }
            }
            stat = "Average"
          }
        }
      }
    }
  }
}
