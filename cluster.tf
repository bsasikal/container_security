provider "aws" {
  region                  = "${var.region}"
  shared_credentials_file = "${var.shared_credentials_file}"
  profile                 = "${var.aws_profile}"
}

// VPC
resource "aws_vpc" "default" {
  cidr_block           = "${var.cidr_block}"
  enable_dns_hostnames = true

  tags = {
    Name   = "${var.vpc_name}"
    Author = "sasi"
    Tool   = "Terraform"
  }
}
// 2 Public Subnets
resource "aws_subnet" "public_subnets" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "10.0.${count.index * 2 + 1}.0/24"
  availability_zone       = "${element(var.availability_zones, count.index)}"
  map_public_ip_on_launch = true

  count = "${var.public_count}"

  tags = {
    Name   = "public_10.0.${count.index * 2 + 1}.0_${element(var.availability_zones, count.index)}"
    Author = "sasi"
    Tool   = "Terraform"
  }
}

// Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.default.id}"

  tags = {
    Name   = "igw_${var.vpc_name}"
    Author = "sasi"
    Tool   = "Terraform"
  }
}

// 2 Private Subnets
resource "aws_subnet" "private_subnets" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "10.0.${count.index * 2}.0/24"
  availability_zone       = "${element(var.availability_zones, count.index)}"
  map_public_ip_on_launch = false

  count = "${var.private_count}"

  tags = {
    Name   = "private_10.0.${count.index * 2}.0_${element(var.availability_zones, count.index)}"
    Author = "sasi"
    Tool   = "Terraform"
  }
}

// Static IP for Nat Gateway
resource "aws_eip" "nat" {
  vpc = true

  tags = {
    Name   = "eip-nat_${var.vpc_name}"
    Author = "sasi"
    Tool   = "Terraform"
  }
}

// Nat Gateway
resource "aws_nat_gateway" "nat" {
  allocation_id = "${aws_eip.nat.id}"
  subnet_id     = "${element(aws_subnet.public_subnets.*.id, 0)}"

  tags = {
    Name   = "nat_${var.vpc_name}"
    Author = "sasi"
    Tool   = "Terraform"
  }
}

// Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = "${aws_vpc.default.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw.id}"
  }

  tags = {
    Name   = "public_rt_${var.vpc_name}"
    Author = "sasi"
    Tool   = "Terraform"
  }
}

// Associate public subnets to public route table
resource "aws_route_table_association" "public" {
  count          = "${var.public_count}"
  subnet_id      = "${element(aws_subnet.public_subnets.*.id, count.index)}"
  route_table_id = "${aws_route_table.public_rt.id}"
}

// Private Route Table
resource "aws_route_table" "private_rt" {
  vpc_id = "${aws_vpc.default.id}"

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.nat.id}"
  }

  tags = {
    Name   = "private_rt_${var.vpc_name}"
    Author = "sasi"
    Tool   = "Terraform"
  }
}

// Associate private subnets to private route table
resource "aws_route_table_association" "private" {
  count          = "${var.private_count}"
  subnet_id      = "${element(aws_subnet.private_subnets.*.id, count.index)}"
  route_table_id = "${aws_route_table.private_rt.id}"
}

// Create security group
resource "aws_security_group" "jump_host" {
  name        = "jump_host_sg_${var.vpc_name}"
  description = "Allow SSH from SG"
  vpc_id      = "${aws_vpc.default.id}"

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name   = "jump_host_sg_${var.vpc_name}"
    Author = "sasi"
    Tool   = "Terraform"
  }
}

//public key for ssh
resource "aws_key_pair" "demo" {
  key_name   = "demo"
  public_key = "${file("${var.public_key}")}"
}

// define jump host AMI image to use
data "aws_ami" "jump_host" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["bastion"]
  }
}

// Jump host launch configuration
resource "aws_launch_configuration" "jump_host_conf" {
  name            = "jump_host"
  image_id        = "${data.aws_ami.jump_host.id}"
  instance_type   = "${var.instance_type}"
  key_name        = "${aws_key_pair.demo.key_name}"
  security_groups = ["${aws_security_group.jump_host.id}"]

  lifecycle {
    create_before_destroy = true
  }
}

// Jump Host ASG
resource "aws_autoscaling_group" "jump_host_asg" {
  name                 = "jump_host_asg_${var.vpc_name}"
  launch_configuration = "${aws_launch_configuration.jump_host_conf.name}"
  #vpc_zone_identifier  = ["${aws_subnet.public_subnets.*.id}"]
  vpc_zone_identifier  = ["${aws_subnet.public_subnets.0.id}"]
  min_size             = 1
  max_size             = 1

  lifecycle {
    create_before_destroy = true
  }


}


