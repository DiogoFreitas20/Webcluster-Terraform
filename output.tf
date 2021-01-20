output "aws_launch_configuration_portoeditora_associate_public_ip_address" {
  value = aws_launch_configuration.portoeditora.associate_public_ip_address
}

output "aws_autoscaling_group_portoeditora_load_balancers"{
  value = aws_autoscaling_group.portoeditora.load_balancers
}

output "aws_lb_portoeditora_alb_dns_name" {
  value       = aws_lb.portoeditora.dns_name
  description = "The domain name of the load balancer"
}

output "init_script" {
  description = "Script to be executed upon booting. "
  value = data.template_cloudinit_config.config.rendered
}

