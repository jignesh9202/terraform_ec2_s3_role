output "Instance_public_DNS"{
    value = aws_instance.ec2-s3.public_dns
}