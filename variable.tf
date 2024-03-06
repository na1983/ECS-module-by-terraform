variable "vpc_cidr" {
    default = "10.0.0.0/16"
}
variable "vpc_id" {
    default = "aws_vpc.master.id"
}
variable "image_id" {
    default ="ami-062c116e449466e7f"
}
variable "instance_type" {
    default = "t3.micro"
}
variable "load_balancer_typ" {
    default = "application"
}
variable "subnets" {
    default = ["aws_subnet.subnet.id," , "aws_subnet.subnet.id"]
}
variable "security_group" {
    default = ["aws_security_group.security_group.id"]
}
variable "network_mode" {
    default = "awsvpc"
}
variable "cpu" {
    default = "256"
}
variable "memory" {
    default = "512"
}
variable "operating_system_family" {
    default = "LINUX"
}
variable "cpu_architecture" {
    default = "X86_64"
}