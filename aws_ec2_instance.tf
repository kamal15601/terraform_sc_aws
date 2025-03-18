module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "terraform-vpc"
  cidr = "172.36.0.0/16"

  azs             = ["ap-south-1a"]
  private_subnets = ["172.36.1.0/24", "172.36.2.0/24", "172.36.3.0/24"]
  public_subnets  = ["172.36.6.0/24", "172.36.5.0/24", "172.36.4.0/24"]

  enable_dns_hostnames = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
    name        = "jenkins_server"
  }
}

module "jenkins_server_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "jenkins_server_sg"
  description = "Security group for user-service with custom ports open within VPC, and PostgreSQL publicly open"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["172.36.4.0/24"]
  ingress_rules       = ["https-443-tcp"]
  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "nignx port"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "ssh"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      description = "Allow HTTPS"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      description = "jenkins port"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}




module "ec2_instance" {
  source = "terraform-aws-modules/ec2-instance/aws"

  name                        = "jenkins_server"
  ami                         = "ami-00bb6a80f01f03502"
  instance_type               = "t2.micro"
  key_name                    = "demo-vpc"
  monitoring                  = true
  vpc_security_group_ids      = [module.jenkins_server_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  associate_public_ip_address = true
  user_data                   = file("script.sh")

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

