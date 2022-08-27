data "aws_ami_ids" "ubuntu" {
  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/ubuntu-*-*-amd64-server-*"]
  }
}

data "aws_vpc" "selected" {
  filter {
    name = "tag:Name"
    values = ["vpc-138"]
  }
}

data "aws_subnet" "selected" {
  filter {
    name = "tag:Name"
    values = ["public_1"]
  }
}

resource "aws_instance" "ec2-s3" {
  //ami = data.aws_ami_ids.ubuntu.ids[0]
  ami = "ami-052efd3df9dad4825"
  instance_type = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.test_profile.name
  subnet_id = data.aws_subnet.selected.id
  vpc_security_group_ids = [aws_security_group.my-sg.id]
  key_name = "jenkins_server"
  user_data = <<EOF
sudo apt-get update
sudo apt-get install openjdk-8-jdk
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt-get update
sudo apt-get install jenkins
sudo apt install git
EOF
}

resource "aws_security_group" "my-sg" {
  name   = "my_sg"
  vpc_id = data.aws_vpc.selected.id

  # HTTP access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

}
resource "aws_iam_role" "allow-list-s3" {
  name = "allow_list_s3"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "s3-policy" {
  name        = "s3_list"
  description = "S3 policy"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObjectAcl",
                "s3:GetObject",
                "s3:GetObjectAttributes",
                "s3:GetObjectVersion"
            ],
            "Resource": "arn:aws:s3:::*/*"
        },
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": [
                "s3:ListBucketMultipartUploads",
                "s3:PutBucketWebsite",
                "s3:ListBucketVersions",
                "s3:ListBucket",
                "s3:GetBucketAcl",
                "s3:GetBucketNotification",
                "s3:PutBucketVersioning"
            ],
            "Resource": "arn:aws:s3:::*"
        },
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": [
                "s3:GetAccessPoint",
                "s3:PutAccountPublicAccessBlock",
                "s3:GetAccountPublicAccessBlock",
                "s3:ListAllMyBuckets",
                "s3:PutAccessPointPublicAccessBlock",
                "s3:PutStorageLensConfiguration",
                "s3:CreateJob"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}
resource "aws_iam_role_policy_attachment" "s3-policy-attach" {
  role       = aws_iam_role.allow-list-s3.name
  policy_arn = aws_iam_policy.s3-policy.arn
}

resource "aws_iam_instance_profile" "test_profile" {
  name = "s3_profile"
  role = aws_iam_role.allow-list-s3.name
}