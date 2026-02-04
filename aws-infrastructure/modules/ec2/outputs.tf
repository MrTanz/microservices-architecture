output "application_load_balancer_sg_id" {
  value = aws_security_group.application_load_balancer_sg.id

}
output "application_load_balancer_tg_arn" {
  value = aws_lb_target_group.application_load_balancer_tg.arn
}

output "bastion_host_security_group_id" {
  value = aws_security_group.bastion_host_security_group.id
}