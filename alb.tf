# ------------------------------------------------------------
# alb.tf  -  "ALB" and "Target group  Grafana :3000" in the diagram
# Users open the ALB link. The ALB sends them to Grafana on
# monitoring-a OR monitoring-b. If one server dies, it uses the other.
# ------------------------------------------------------------

# Application Load Balancer, placed in both public subnets
resource "aws_lb" "alb" {
  name               = "monitoring-alb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]
  tags               = { Name = "monitoring-alb" }
}

# Target group: the list of servers the ALB can send users to (Grafana on port 3000)
resource "aws_lb_target_group" "grafana" {
  name     = "grafana-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  # Every few seconds the ALB checks that Grafana answers. Dead servers get no users.
  health_check {
    path    = "/api/health"
    matcher = "200"
  }

  # Keep a user on the same Grafana so they stay logged in
  stickiness {
    type    = "lb_cookie"
    enabled = true
  }
}

# Put both monitoring servers into the target group
resource "aws_lb_target_group_attachment" "monitoring_a" {
  target_group_arn = aws_lb_target_group.grafana.arn
  target_id        = aws_instance.monitoring_a.id
  port             = 3000
}

resource "aws_lb_target_group_attachment" "monitoring_b" {
  target_group_arn = aws_lb_target_group.grafana.arn
  target_id        = aws_instance.monitoring_b.id
  port             = 3000
}

# Listener: "when someone opens the ALB on port 80, forward them to the target group"
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana.arn
  }
}
