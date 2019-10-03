provider "aws" {
  region                  = var.region
  shared_credentials_file = var.shared_credentials_file
  profile                 = var.aws_profile
}

// VPC
resource "aws_vpc" "default" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true

  tags = {
    Name   = var.vpc_name
    Author = "sasi"
    Tool   = "Terraform"
  }
}
// 2 Public Subnets
resource "aws_subnet" "public_subnets" {
  vpc_id                  = aws_vpc.default.id
  cidr_block              = "10.0.${count.index * 2 + 1}.0/24"
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  count = var.public_count

  tags = {
    Name   = "public_10.0.${count.index * 2 + 1}.0_${element(var.availability_zones, count.index)}"
    Author = "sasi"
    Tool   = "Terraform"
  }
}

// Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.default.id

  tags = {
    Name   = "igw_${var.vpc_name}"
    Author = "sasi"
    Tool   = "Terraform"
  }
}

// 2 Private Subnets
resource "aws_subnet" "private_subnets" {
  vpc_id                  = aws_vpc.default.id
  cidr_block              = "10.0.${count.index * 2}.0/24"
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  count = var.private_count

  tags = {
    Name   = "private_10.0.${count.index * 2}.0_${element(var.availability_zones, count.index)}"
    Author = "sasi"
    Tool   = "Terraform"
  }
}

// Static IP for Nat Gateway
resource "aws_eip" "nat" {
  vpc = true
  //count = "${length(split(",", var.availability_zones))}}"
  count = 2

  tags = {
    Name   = "eip-nat_${var.vpc_name}"
    Author = "sasi"
    Tool   = "Terraform"
  }
}

// Nat Gateway
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.*.id[count.index]
  subnet_id     = aws_subnet.public_subnets.*.id[count.index]
  count         = var.public_count

  tags = {
    Name   = "nat_${var.vpc_name}"
    Author = "sasi"
    Tool   = "Terraform"
  }
}

// Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.default.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name   = "public_rt_${var.vpc_name}"
    Author = "sasi"
    Tool   = "Terraform"
  }
}

// Associate public subnets to public route table
resource "aws_route_table_association" "public" {
  count          = var.public_count
  subnet_id      = aws_subnet.public_subnets.*.id[count.index]
  route_table_id = aws_route_table.public_rt.id
}

// Private Route Table
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.default.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.*.id[count.index]
  }
  count = var.private_count

  tags = {
    Name   = "private_rt_${var.vpc_name}"
    Author = "sasi"
    Tool   = "Terraform"
  }
}

// Associate private subnets to private route table
resource "aws_route_table_association" "private" {
  count          = var.private_count
  subnet_id      = aws_subnet.private_subnets.*.id[count.index]
  route_table_id = aws_route_table.private_rt.*.id[count.index]
}

// Create security group
resource "aws_security_group" "jump_host" {
  name        = "jump_host_sg_${var.vpc_name}"
  description = "Allow SSH from SG"
  vpc_id      = aws_vpc.default.id

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
  public_key = file(var.public_key)
}

// define jump host AMI image to use
data "aws_ami" "jump_host" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["jumphost"]
  }
}

// Jump host launch configuration
resource "aws_launch_configuration" "jump_host_conf" {
  name            = "jump_host"
  image_id        = data.aws_ami.jump_host.id
  instance_type   = var.instance_type
  key_name        = aws_key_pair.demo.key_name
  security_groups = [aws_security_group.jump_host.id]

  lifecycle {
    create_before_destroy = true
  }
}

// Jump Host ASG
resource "aws_autoscaling_group" "jump_host_asg" {
  name = "jump_host_asg_${var.vpc_name}"
  launch_configuration = aws_launch_configuration.jump_host_conf.name
  #vpc_zone_identifier  = ["${aws_subnet.public_subnets.*.id}"]
  #vpc_zone_identifier = [aws_subnet.public_subnets[0].id]
  vpc_zone_identifier = aws_subnet.public_subnets.*.id
  min_size = 1
  max_size = 1

  lifecycle {
    create_before_destroy = true
  }
}

// define Jenkins master AMI image to use
data "aws_ami" "jenkins-master" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["insight-jenkins-master"]
  }
}

/*
// create security group for Jenkins Master
resource "aws_security_group" "jenkins_master_sg" {
  name        = "jenkins_master_sg"
  description = "Allow traffic on port 8080 and enable SSH"
  vpc_id      = aws_vpc.default.id

  ingress {
    from_port       = "22"
    to_port         = "22"
    protocol        = "tcp"
    //security_groups = ["${aws_security_group.jump_host.id}"]
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = "8080"
    to_port         = "8080"
    protocol        = "tcp"
    //cidr_blocks     = ["${var.cidr_block}"]
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name   = "jenkins_master_sg"
    Author = "sasi"
    Tool   = "Terraform"
  }
}

// Jenkins Master Host launch configuration
resource "aws_instance" "jenkins_master" {
  ami                    = data.aws_ami.jenkins-master.id
  instance_type          = var.jenkins_master_instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.jenkins_master_sg.id]
  #subnet_id              = aws_subnet.public_subnets[0].id
  subnet_id              = aws_subnet.public_subnets.0.id


  root_block_device {
    volume_type           = "gp2"
    volume_size           = 30
    delete_on_termination = false
  }

  tags = {
    Name   = "jenkins_master"
    Author = "sasi"
    Tool   = "Terraform"
  }

  provisioner "local-exec" {
    command = "rm -rf /tmp/jenkins-master-ip && echo http://${aws_instance.jenkins_master.public_ip}:8080 >> /tmp/jenkins-master-ip"
  }

}
*/

// above two configurations were commented in favor of below to support routing through ALB
resource "aws_launch_configuration" "jenkins_master_launch_configuration" {
  name_prefix     = "jenkins_masters_asg_"
  image_id        = data.aws_ami.jenkins-master.id
  instance_type   = var.jenkins_master_instance_type
  security_groups = [aws_security_group.public_subnet_lb_security_group.id]

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_security_group.public_subnet_lb_security_group]
}

resource "aws_autoscaling_group" "jenkins_masters_asg" {
  name_prefix          = "jenkins_masters_asg_"
  launch_configuration = aws_launch_configuration.jenkins_master_launch_configuration.name
  //vpc_zone_identifier  = ["${aws_subnet.public_subnets.*.id[count.index]}"]
  vpc_zone_identifier  = aws_subnet.public_subnets.*.id
  //count                = var.public_count
  //count                = 2
  min_size             = 2
  max_size             = 2
  target_group_arns    = ["${aws_alb_target_group.public_subnet_alb_target_group.id}", "${aws_alb_target_group.public_subnet_alb_tgt_grp_ssh.id}"]

  depends_on = [aws_launch_configuration.jenkins_master_launch_configuration]

  lifecycle {
    create_before_destroy = true
  }
}


/*
 * Jenkins Slave Configurations starts from here
 * Keep the slaves configurations in a separate file to handle the deployment independent of Master
*/

// Jenkins Slave Image
data "aws_ami" "jenkins-slave" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["insight-jenkins-slave"]
  }
}

// create security group for Jenkins Slaves
resource "aws_security_group" "jenkins_slaves_sg" {
  name        = "jenkins_slaves_sg"
  description = "Allow traffic on port 22 from Jenkins Master SG"
  vpc_id      = aws_vpc.default.id

  ingress {
    from_port       = "22"
    to_port         = "22"
    protocol        = "tcp"
    //security_groups = ["${aws_security_group.jenkins_master_sg.id}", "${aws_security_group.jump_host.id}"]
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port       = "0"
    to_port         = "0"
    protocol        = "-1"
    //security_groups = ["${aws_security_group.jenkins_master_sg.id}", "${aws_security_group.jump_host.id}"]
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port       = "8080"
    to_port         = "8080"
    protocol        = "tcp"
    //security_groups = ["${aws_security_group.jenkins_master_sg.id}", "${aws_security_group.jump_host.id}"]
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name   = "jenkins_slaves_sg"
    Author = "sasi"
    Tool   = "Terraform"
  }
}

// Jenkins slaves resource template
data "template_file" "user_data_slave" {
  template = file("scripts/join-cluster.tpl")

  vars  = {
    jenkins_url            = "http://${aws_alb.public_subnet_alb.dns_name}:80"
    jenkins_username       = var.jenkins_username
    jenkins_password       = var.jenkins_password
    jenkins_credentials_id = var.jenkins_credentials_id
  }
}

// Jenkins slaves launch configuration
resource "aws_launch_configuration" "jenkins_slave_launch_conf" {
  name                 = "jenkins_slaves_config"
  image_id             = data.aws_ami.jenkins-slave.id
  instance_type        = var.jenkins_slave_instance_type
  key_name             = var.key_name
  security_groups      = [aws_security_group.jenkins_slaves_sg.id]
  user_data            = data.template_file.user_data_slave.rendered

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 30
    delete_on_termination = false
  }

  lifecycle {
    create_before_destroy = true
  }
}

// ASG Jenkins slaves
resource "aws_autoscaling_group" "jenkins_slaves" {
  name                 = "jenkins_slaves_asg"
  launch_configuration = aws_launch_configuration.jenkins_slave_launch_conf.name

  #vpc_zone_identifier = [aws_subnet.private_subnets[0].id]
  vpc_zone_identifier = aws_subnet.private_subnets.*.id
  min_size = 3
  max_size = 3

  #depends_on = ["aws_instance.jenkins_master"]

  lifecycle {
    create_before_destroy = true
  }
}

//SNS Email Module
data "template_file" "cloudformation_sns_stack" {
  template = "${file("${path.module}/scripts/email-sns-stack.json.tpl")}"
  vars = {
          display_name  = "${var.display_name}"
          subscriptions = "${join("," , formatlist("{ \"Endpoint\": \"%s\", \"Protocol\": \"%s\"  }", var.email_addresses, var.protocol))}"
  }
}

resource "aws_cloudformation_stack" "sns_topic" {
  name          = "${var.stack_name}"
  template_body = "${data.template_file.cloudformation_sns_stack.rendered}"
  tags = "${merge(map("Name", "${var.stack_name}"))}"

}


