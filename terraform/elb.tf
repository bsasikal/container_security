# adding load balancer configurations for Jenkins master

// create security group for Jenkins Master
resource "aws_security_group" "public_subnet_lb_security_group" {
  name        = "public_subnet_lb_security_group"
  description = "Allow traffic on port 8080 and enable SSH"
  vpc_id      = aws_vpc.default.id

  ingress {
    from_port       = "22"
    to_port         = "22"
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = "80"
    to_port         = "8080"
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = "8080"
    to_port         = "8080"
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  depends_on = [aws_vpc.default]

  tags = {
    Name   = "public_subnet_lb_security_group"
    Author = "sasi"
    Tool   = "Terraform"
  }
}

// create target group
// for jenkins
resource "aws_alb_target_group" "public_subnet_alb_target_group" {
  name     = "public-subnet-alb-target-group"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.default.id

  stickiness {
    type = "lb_cookie"
    enabled = true
  }

  depends_on = [aws_vpc.default]
}

// for ssh
resource "aws_alb_target_group" "public_subnet_alb_tgt_grp_ssh" {
  name     = "public-subnet-alb-tgt-grp-ssh"
  port     = 22
  protocol = "TCP"
  vpc_id   = aws_vpc.default.id

  depends_on = [aws_vpc.default]
}

// create alb
resource "aws_alb" "public_subnet_alb" {
  name               = "public-subnet-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.public_subnet_lb_security_group.id]
  //subnets            = ["${aws_subnet.public_subnets.*.id[count.index]}"]
  subnets            = aws_subnet.public_subnets.*.id
  //count              = var.public_count
  //count              = 2
  enable_deletion_protection = false

  tags = {
    Name   = "public_subnet_alb"
    Author = "sasi"
    Tool   = "Terraform"
    Environment = "production"
  }

  depends_on = [aws_security_group.public_subnet_lb_security_group, aws_subnet.public_subnets]
}

// create listener
resource "aws_alb_listener" "public_subnet_alb_listener" {
  //load_balancer_arn = aws_alb.public_subnet_alb.*.id[count.index]
  load_balancer_arn = aws_alb.public_subnet_alb.id
  port              = 80
  protocol          = "HTTP"
  //count             = var.public_count
  //count             = 2
  default_action {
    target_group_arn = aws_alb_target_group.public_subnet_alb_target_group.id
    type = "forward"
  }
  depends_on = [aws_alb.public_subnet_alb, aws_alb_target_group.public_subnet_alb_target_group]
}

/*
resource "aws_alb_listener" "public_subnet_alb_listener_ssh" {
  load_balancer_arn = aws_alb.public_subnet_alb.*.id[count.index]
  port              = 22
  protocol          = "TCP"
  //count             = var.public_count
  count             = 1
  default_action {
    target_group_arn = aws_alb_target_group.public_subnet_alb_tgt_grp_ssh.id
    type = "forward"
  }
  depends_on = [aws_alb.public_subnet_alb, aws_alb_target_group.public_subnet_alb_tgt_grp_ssh]
}
*/