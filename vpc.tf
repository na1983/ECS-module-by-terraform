resource "aws_vpc" "master" {
 cidr_block           = var.vpc_cidr
 enable_dns_hostnames = true
 tags = {
   name = "master"
 }
}
#Add 2 subnets
resource "aws_subnet" "subnet" {
 vpc_id                  = var.vpc_id
 cidr_block              = cidrsubnet(aws_vpc.master.cidr_block, 8, 1)
 map_public_ip_on_launch = true
 availability_zone       = "eu-central-1a"
}

resource "aws_subnet" "subnet2" {
 vpc_id                  = var.vpc_id
 cidr_block              = cidrsubnet(aws_vpc.master.cidr_block, 8, 2)
 map_public_ip_on_launch = true
 availability_zone       = "eu-central-1b"
}
#Create internet gateway (IGW)
resource "aws_internet_gateway" "internet_gateway" {
 vpc_id = var.vpc_id
 tags = {
   Name = "internet_gateway"
 }
}
