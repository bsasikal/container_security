output "vpc_id" {
  value = aws_vpc.default.id
}

output "public_subnets" {
  value = aws_subnet.public_subnets.*.id
}

output "private_subnets" {
  value = aws_subnet.private_subnets.*.id
}

output "jenkins_master_url" {
  value =  "http://${aws_instance.jenkins_master.public_ip}:8080"
}

output "arn" {
  value       = "${aws_cloudformation_stack.sns_topic.outputs["ARN"]}"
  description = "Email SNS topic ARN"
}
