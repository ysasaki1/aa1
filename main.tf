##############################################################################
# Create an RDS MySQL database - get dbname, username, and password using the
# ${var} function
##############################################################################
resource "aws_db_instance" "project_db" {
  allocated_storage    = 10
  db_name             = var.dbname
  engine              = "mysql"
  engine_version      = "8.0"
  instance_class      = "db.t3.micro"
  username            = var.uname
  password            = var.pass
  skip_final_snapshot = true
}

output "db_name" {
  description = "Database Name"
  value       = aws_db_instance.project_db.db_name
}

output "db_address" {
  description = "Database Address"
  value       = aws_db_instance.project_db.endpoint
}

##############################################################################
# Create 2 S3 buckets - pull their names from the terraform.tfvars using the
# ${var} function
##############################################################################
resource "aws_s3_bucket" "raw_bucket" {
  bucket = var.raw_bucket_name

  tags = {
    Name        = var.tag_name
    Environment = "Dev"
  }
}

resource "aws_s3_bucket" "finished_bucket" {
  bucket = var.finished_bucket_name

  tags = {
    Name        = var.tag_name
    Environment = "Dev"
  }
}

output "raw_url" {
  description = "Raw Bucket URL"
  value       = aws_s3_bucket.raw_bucket.bucket
}

output "finished_url" {
  description = "Finished Bucket URL"
  value       = aws_s3_bucket.finished_bucket.bucket
}

##############################################################################
# Create an SNS Topic
##############################################################################
resource "aws_sns_topic" "user_updates" {
  name = var.sns_topic_name

  tags = {
    Name        = var.tag_name
    Environment = "project"
  }
}

##############################################################################
# Create an SQS Message Queue
##############################################################################
resource "aws_sqs_queue" "terraform_queue" {
  name = var.sqs_queue_name

  tags = {
    Name        = var.tag_name
    Environment = "project"
  }
}

output "sqs_url" {
  description = "SQS Queue URL"
  value       = aws_sqs_queue.terraform_queue.id
}

##############################################################################
# Create launch template
##############################################################################
resource "aws_launch_template" "lt" {
  image_id                = var.image_id
  instance_type           = var.instance_type
  key_name                = var.key_name
  vpc_security_group_ids   = [var.security_group_id]

  tags = {
    Name = var.tag_name
  }
  
  user_data = filebase64("./install-env.sh")
}

##############################################################################
# Gather a list of all subnets per AZ per your region
##############################################################################
data "aws_vpc" "main" {
  default = true
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
}

output "list-of-subnets" {
  description = "List of subnets"
  value       = data.aws_subnets.public.ids
}

data "aws_availability_zones" "available" {
  state = "available"
}

output "list-of-azs" {
  description = "List of AZs"
  value       = data.aws_availability_zones.available.names
}

##############################################################################
# Create Load Balancer
##############################################################################
resource "aws_lb" "lb" {
  name               = var.lb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.security_group_id]
  subnets            = data.aws_subnets.public.ids

  enable_deletion_protection = false

  tags = {
    Name        = var.tag_name
    Environment = "project"
  }
}

output "url" {
  value = aws_lb.lb.dns_name
}

##############################################################################
# Create autoscaling group
##############################################################################
resource "aws_autoscaling_group" "asg" {
  name                      = var.asg_name
  max_size                  = var.max_size
  min_size                  = var.min_size
  health_check_grace_period = 300
  health_check_type         = "EC2"
  desired_capacity          = var.desired_capacity
  force_delete              = true
  target_group_arns         = [aws_lb_target_group.alb_lb_tg.arn]
  availability_zones        = data.aws_availability_zones.available.names

  launch_template {
    id = aws_launch_template.lt.id
  }  
}

##############################################################################
# Create a new ALB Target Group attachment
##############################################################################
resource "aws_autoscaling_attachment" "asg_attach" {
  depends_on = [aws_lb.lb]
  autoscaling_group_name = aws_autoscaling_group.asg.name
  lb_target_group_arn    = aws_lb_target_group.alb_lb_tg.arn
}

##############################################################################
# Create Load Balancer Target Group
##############################################################################
resource "aws_lb_target_group" "alb_lb_tg" {
  depends_on = [aws_lb.lb]
  name       = var.lb_tg_name
  target_type = "instance"
  port       = 80
  protocol   = "HTTP"
  vpc_id     = data.aws_vpc.main.id
}

##############################################################################
# Create Load Balancer Listener
##############################################################################
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_lb_tg.arn
  }
}
