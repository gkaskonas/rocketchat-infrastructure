variable "number_of_instances" {
  
}

variable "instance_ids" {
  
}

variable "vpc_id" {
  
}

variable "sg_id" {
  
}

variable "subnet_ids" {
  
}




resource "aws_lb_target_group_attachment" "test" {
  count            = "${var.number_of_instances}"
  target_group_arn = "${aws_lb_target_group.rocketchat.arn}"
  target_id        = "${element(var.instance_ids, count.index)}"
  port             = 80
}

resource "aws_lb_target_group" "rocketchat" {
  name        = "alb-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = "${var.vpc_id}"
  target_type = "instance"
  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 6
    protocol            = "HTTP"
    matcher             = "200-399"
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = "${aws_lb.test.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.rocketchat.arn}"
  }
}

resource "aws_lb_listener_rule" "static" {
  listener_arn = "${aws_lb_listener.front_end.arn}"
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.rocketchat.arn}"
  }

  condition {
    field  = "path-pattern"
    values = ["/"]
  }
}

# Create a new load balancer
resource "aws_lb" "test" {

  name = "alb-rocketchat"

  load_balancer_type = "application"

  subnets         = "${var.subnet_ids}"
  security_groups = "${var.sg_id}"
  internal        = false

  tags = {
    Owner       = "user"
    Environment = "dev"
  }
}


output "dns_name" {
  value = "${aws_lb.test.dns_name}"
}
