# ------------------------------------------------------------
# ansible.tf  -  makes it ONE CLICK
# 1. Writes inventory.ini with the real server IPs.
# 2. Runs Ansible (playbook.yml) automatically once the servers exist.
# So "terraform apply" builds AWS AND installs all the software.
# ------------------------------------------------------------

locals {
  key = pathexpand(var.private_key_path) # turns ~/.ssh/x.pem into a full path
}

# Step 1: the list of servers for Ansible
resource "local_file" "inventory" {
  filename = "${path.module}/inventory.ini"
  content  = <<-EOT
    # Created by Terraform. Do not edit by hand.
    [monitoring]
    monitoring-a ansible_host=${aws_instance.monitoring_a.private_ip}
    monitoring-b ansible_host=${aws_instance.monitoring_b.private_ip}

    [monitoring:vars]
    ansible_user=ubuntu
    ansible_ssh_private_key_file=${local.key}
    # The servers are private, so Ansible "jumps" through the bastion host to reach them
    ansible_ssh_common_args='-o StrictHostKeyChecking=no -o ProxyCommand="ssh -i ${local.key} -o StrictHostKeyChecking=no -W %h:%p ubuntu@${aws_instance.bastion.public_ip}"'
  EOT
}

# Step 2: run Ansible. It runs again only if the servers or the playbook change.
resource "terraform_data" "run_ansible" {
  triggers_replace = [
    aws_instance.monitoring_a.id,
    aws_instance.monitoring_b.id,
    aws_instance.bastion.id,
    filemd5("${path.module}/playbook.yml"),
  ]

  depends_on = [local_file.inventory, aws_nat_gateway.nat, aws_route_table_association.private_1, aws_route_table_association.private_2]

  provisioner "local-exec" {
    working_dir = path.module
    command     = "ansible-playbook playbook.yml"
    environment = {
      ANSIBLE_CONFIG = "ansible.cfg"
    }
  }
}
