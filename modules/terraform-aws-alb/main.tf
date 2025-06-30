 resource "aws_security_group" "alb_sg" {
   name        = "alb_sg"
   description = "Allow HTTP inbound to ALB"
   vpc_id      = var.vpc_id

   ingress {
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
 }


resource "aws_lb" "alb" {
  name               = var.alb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.public_subnet_ids
 }


resource "aws_lb_target_group" "tg" {
   count    = 3
   name     = "tg-${count.index}"
   port     = 80
   protocol = "HTTP"
   vpc_id   = var.vpc_id
   target_type = "instance"

   health_check {
     path                = "/"
     protocol            = "HTTP"
     matcher             = "200"
     interval            = 30
     timeout             = 5
     healthy_threshold   = 2
     unhealthy_threshold = 2
   }
 }


 resource "aws_lb_target_group_attachment" "attach" {
   count            = 3
   target_group_arn = aws_lb_target_group.tg[count.index].arn
   target_id        = var.public_instance_ids[count.index]
   port             = 80
 }


resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg[0].arn
  }
}


resource "aws_lb_listener_rule" "image" {
  count=2
  listener_arn = aws_lb_listener.http.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg[1].arn
  }

  condition {
    path_pattern {
      values = ["/image/*"]
    }
  }
}

resource "aws_lb_listener_rule" "register" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 20

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg[2].arn
  }

  condition {
    path_pattern {
      values = ["/register/*"]
    }
  }
}