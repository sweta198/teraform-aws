Skip to content
Search or jump to…
Pull requests
Issues
Marketplace
Explore
 
@sweta198 
balajirb
/
terraform-aws
Public
Code
Issues
Pull requests
Actions
Projects
Wiki
Security
Insights
terraform-aws/main.tf
@balajirb
balajirb Add files via upload
Latest commit 15d4344 on Oct 2, 2021
 History
 1 contributor
104 lines (88 sloc)  2.32 KB
   
#Create 
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = "us-west-2"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]

}


variable "ingressrules" {
 type    = list(number)
 default = [22, 8080]
}


resource "aws_security_group" "web_traffic" {
  name        = "Allow web traffic"
  description = "Allow ssh and standard http/https ports inbound and everything outbound"

  dynamic "ingress" {
    iterator = port
    for_each = var.ingressrules
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "TCP"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Terraform" = "true"
  }
}
output "instance_ips" {
  value = aws_instance.jenkins.public_ip
}
resource "aws_instance" "jenkins" {
  ami             = data.aws_ami.ubuntu.id
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.web_traffic.name]
  key_name        = "jenkins-key-pair"

  provisioner "remote-exec" {
    inline = [
      "wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -",
      "sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'",
      "sudo apt update -qq",
      "sudo apt install software-properties-common -y",
      "sudo add-apt-repository ppa:deadsnakes/ppa -y",
      "sudo apt install -y python",
      "sudo apt install -y openjdk-11-jdk",
      "sudo apt install jenkins -y",
      "JAVA_HOME=/usr/lib/jvm/openjdk-11",
      "PATH=$PATH:$JAVA_HOME/bin",
      "export PATH",
      "sudo systemctl start jenkins",
    ]
  }
  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ubuntu"
    private_key = file("./jenkins-key-pair.pem")
  }
  tags = {
    "Name"      = "Jenkins_Server"
    "Terraform" = "true"
  }

}
© 2022 GitHub, Inc.
Terms
Privacy
Security
Status
Docs
Contact GitHub
Pricing
API
Training
Blog
About
Loading complete