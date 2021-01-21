resource "aws_launch_configuration" "portoeditora" {

  image_id = "ami-0885b1f6bd170450c"
  instance_type = "t2.micro"
  key_name = var.key_name
  security_groups = [
    aws_security_group.instance.id]

  user_data = data.template_cloudinit_config.config.rendered

  root_block_device {
    volume_size = var.volume_size
  }

  # Required when using a launch configuration with an auto scaling group.
  # https://www.terraform.io/docs/providers/aws/r/launch_configuration.html
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "portoeditora" {
  launch_configuration = aws_launch_configuration.portoeditora.name
  vpc_zone_identifier = data.aws_subnet_ids.default.ids

  target_group_arns = [
    aws_lb_target_group.asg.arn]
  health_check_type = "ELB"

  min_size = 1
  max_size = 3

  tag {
    key = "Name"
    value = "terraform-asg-portoeditora"
    propagate_at_launch = true
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

resource "aws_lb" "portoeditora" {
  name = var.alb_name
  load_balancer_type = "application"
  subnets = data.aws_subnet_ids.default.ids
  security_groups = [
    aws_security_group.instance.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.portoeditora.arn
  port = 80
  protocol = "HTTP"

  # By default, return a simple 404 page
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code = 404
    }
  }
}

resource "aws_lb_target_group" "asg" {

  name = var.alb_name

  port = 80
  protocol = "HTTP"
  vpc_id = data.aws_vpc.default.id

  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "200"
    interval = 15
    timeout = 3
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority = 100

  condition {
    path_pattern {
      values = [
        "*"]
    }
  }

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}

# aws_security_group.instance:
resource "aws_security_group" "instance" {
  name = var.security_group_name
  egress = [
    {
      cidr_blocks = [
        "0.0.0.0/0",
      ]
      description = ""
      from_port = 0
      ipv6_cidr_blocks = []
      prefix_list_ids = []
      protocol = "-1"
      security_groups = []
      self = false
      to_port = 0
    },
  ]
  ingress = [
  for _fw_rule in var.fw_rules:
  {
    cidr_blocks = [
    for _ip in var.ip_list:
    _ip
    ]
    description = _fw_rule[3]
    from_port = _fw_rule[1]
    ipv6_cidr_blocks = []
    prefix_list_ids = []
    protocol = _fw_rule[0]
    security_groups = []
    self = false
    to_port = _fw_rule[2]
  }
  ]
}
