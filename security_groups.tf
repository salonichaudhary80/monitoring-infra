# ------------------------------------------------------------
# security_groups.tf  -  the 3 red dashed boxes in the diagram
# A security group = a firewall around a server.
# ------------------------------------------------------------

# alb-sg: the load balancer accepts web traffic from anyone
resource "aws_security_group" "alb" {
  name   = "alb-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "Website (HTTP) from the internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "alb-sg" }
}

# bastion-sg: SSH only from YOUR laptop
resource "aws_security_group" "bastion" {
  name   = "bastion-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "SSH from my laptop only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "bastion-sg" }
}

# monitoring-sg: both monitoring servers
resource "aws_security_group" "monitoring" {
  name   = "monitoring-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    description     = "Grafana, only from the load balancer"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description = "node_exporter, so each vmagent can scrape both servers"
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  ingress {
    description     = "SSH, only from the bastion host"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  # No rule for VictoriaMetrics (8428): only Grafana on the same server can use it.

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "monitoring-sg" }
}
