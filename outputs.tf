# ------------------------------------------------------------
# outputs.tf  -  what Terraform prints at the end
# ------------------------------------------------------------

output "grafana_url" {
  description = "Open this in your browser (user: admin)"
  value       = "http://${aws_lb.alb.dns_name}"
}

output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "monitoring_a_private_ip" {
  value = aws_instance.monitoring_a.private_ip
}

output "monitoring_b_private_ip" {
  value = aws_instance.monitoring_b.private_ip
}
