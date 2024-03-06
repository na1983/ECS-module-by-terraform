#Create a security group along with ingress and egress rules
resource "aws_security_group" "security_group" {
 name   = "ecs-security-group"
 vpc_id = var.vpc_id

 ingress {
   from_port   = 0
   to_port     = 0
   protocol    = -1
   self        = "false"
   cidr_blocks = ["0.0.0.0/0"]
   description = "any"
 }

 egress {
   from_port   = 0
   to_port     = 0
   protocol    = "-1"
   cidr_blocks = ["0.0.0.0/0"]
 }
}
#Configuring the EC2 instances
resource "aws_launch_template" "ecs_lt" {
 name_prefix   = "ecs-template"
 image_id      = var.image_id
 instance_type = var.instance_type

 vpc_security_group_ids = var.security_group
 iam_instance_profile {
   name = "ecsInstanceRole"
 }

 block_device_mappings {
   device_name = "/dev/xvda"
   ebs {
     volume_size = 30
     volume_type = "gp2"
   }
 }

 tag_specifications {
   resource_type = "instance"
   tags = {
     Name = "ecs-instance"
   }
 }
}


#Create an auto-scaling group (ASG)
resource "aws_autoscaling_group" "ecs_asg" {
 vpc_zone_identifier = var.subnets
 desired_capacity    = 2
 max_size            = 3
 min_size            = 1

 launch_template {
   id      = aws_launch_template.ecs_lt.id
   version = "$Latest"
 }

 tag {
   key                 = "AmazonECSManaged"
   value               = true
   propagate_at_launch = true
 }
}

#Configure Application Load Balancer (ALB)

resource "aws_lb" "ecs_alb" {
 name               = "ecs-alb"
 internal           = false
 load_balancer_type = var.load_balancer_type
 security_groups    = var.security_group
 subnets            = var.subnets

 tags = {
   Name = "ecs-alb"
 }
}

resource "aws_lb_listener" "ecs_alb_listener" {
 load_balancer_arn = aws_lb.ecs_alb.arn
 port              = 80
 protocol          = "HTTP"

 default_action {
   type             = "forward"
   target_group_arn = aws_lb_target_group.ecs_tg.arn
 }
}

resource "aws_lb_target_group" "ecs_tg" {
 name        = "ecs-target-group"
 port        = 80
 protocol    = "HTTP"
 target_type = "ip"
 vpc_id      = var.vpc_id

 health_check {
   path = "/"
 }
}
#Provision ECS cluster
resource "aws_ecs_cluster" "ecs_cluster" {
 name = "my-ecs-cluster"
}
#Create capacity providers
resource "aws_ecs_capacity_provider" "ecs_capacity_provider" {
 name = "test1"

 auto_scaling_group_provider {
   auto_scaling_group_arn = aws_autoscaling_group.ecs_asg.arn

   managed_scaling {
     maximum_scaling_step_size = 1000
     minimum_scaling_step_size = 1
     status                    = "ENABLED"
     target_capacity           = 3
   }
 }
}

resource "aws_ecs_cluster_capacity_providers" "example" {
 cluster_name = aws_ecs_cluster.ecs_cluster.name

 capacity_providers = [aws_ecs_capacity_provider.ecs_capacity_provider.name]

 default_capacity_provider_strategy {
   base              = 1
   weight            = 100
   capacity_provider = aws_ecs_capacity_provider.ecs_capacity_provider.name
 }
}
#Create ECS task definition with Terraform
resource "aws_ecs_task_definition" "ecs_task_definition" {
 family             = "my-ecs-task"
 network_mode       = var.network_mode
 execution_role_arn = "arn:aws:iam::532199187081:role/ecsTaskExecutionRole"
 cpu                = var.cpu
 runtime_platform {
   operating_system_family = var.operating_system_family
   cpu_architecture        = var.cpu_architecture
 }
 container_definitions = jsonencode([
   {
     name      = "nginxdemos-hello"
     image     = "nginxdemos/hello"
     cpu       = var.cpu
     memory    = var.memory
     essential = true
     portMappings = [
       {
         containerPort = 80
         hostPort      = 80
         protocol      = "tcp"
       }
     ]
   }
 ])
}
#Create the ECS service
resource "aws_ecs_service" "ecs_service" {
 name            = "my-ecs-service"
 cluster         = aws_ecs_cluster.ecs_cluster.id
 task_definition = aws_ecs_task_definition.ecs_task_definition.arn
 desired_count   = 2

 network_configuration {
   subnets         = var.subnets
   security_groups = var.security_group
 }

 force_new_deployment = true
 placement_constraints {
   type = "distinctInstance"
 }

 triggers = {
   redeployment = timestamp()
 }

 capacity_provider_strategy {
   capacity_provider = aws_ecs_capacity_provider.ecs_capacity_provider.name
   weight            = 100
 }

 load_balancer {
   target_group_arn = aws_lb_target_group.ecs_tg.arn
   container_name   = "dockergs"
   container_port   = 80
 }

 depends_on = [aws_autoscaling_group.ecs_asg]
}
