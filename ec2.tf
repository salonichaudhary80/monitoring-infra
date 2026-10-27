# ------------------------------------------------------------
# ec2.tf  -  the 3 servers in the diagram
# Bastion host (public), monitoring-a (AZ-1), monitoring-b (AZ-2)
# ------------------------------------------------------------

# Find the latest Ubuntu 24.04 image automatically
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical, the company behind Ubuntu

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

# Bastion host: the "jump server". The only way to SSH into the private servers.
resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public_1.id
  vpc_security_group_ids = [aws_security_group.bastion.id]
  key_name               = var.key_name
  tags                   = { Name = "bastion-host" }
}

# monitoring-a: private subnet in AZ-1 (gets node_exporter, vmagent, VictoriaMetrics, Grafana)
resource "aws_instance" "monitoring_a" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private_1.id
  vpc_security_group_ids = [aws_security_group.monitoring.id]
  key_name               = var.key_name
  tags                   = { Name = "monitoring-a" }
}

# monitoring-b: private subnet in AZ-2 (exact copy of monitoring-a)
resource "aws_instance" "monitoring_b" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private_2.id
  vpc_security_group_ids = [aws_security_group.monitoring.id]
  key_name               = var.key_name
  tags                   = { Name = "monitoring-b" }
}
