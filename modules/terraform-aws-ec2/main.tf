# data "aws_security_group" "sg" {
#   filter {
#     name   = "vpc-id"
#     values = [aws_vpc.main.id]
#   }
#   filter {
#     name   = "group-name"
#     values = ["default"]
#   }
# }
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-http-sg"
  description = "Allow HTTP and SSH"
  vpc_id      = var.vpc_id 

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
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


resource "aws_instance" "public_instances" {
  count         = var.public_instance
  ami           = "ami-0e35ddab05955cf57"
  instance_type = "t3.micro"
  subnet_id     = var.public_subnet_ids[count.index]
  associate_public_ip_address = true
#   security_groups = [data.aws_security_group.sg.id]
  security_groups = [aws_security_group.ec2_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y nginx
              systemctl start nginx
              systemctl enable nginx
              echo "<h1>Hostname: $(hostname)</h1>" > /var/www/html/index.html
              echo "<h1>Hostname: $(hostname)</h1>" > /var/www/html/image/index.html
              echo "<h1>Hostname: $(hostname)</h1>" > /var/www/html/register/index.html
              systemctl reload nginx
              EOF

  tags = {
    Name = "Public-Instance-${count.index}"
  }
}



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
  name               = "usecase-1"
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
   target_id        = aws_instance.public_instances[count.index].id
   port             = 80
 }


resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
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
    target_group_arn = target_group_arn = aws_lb_target_group.tg[1].arn
  }

  condition {
    path_pattern {
      values = ["/images*"]
    }
  }
}

resource "aws_lb_listener_rule" "register" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 20

  action {
    type             = "forward"
    target_group_arn = target_group_arn = aws_lb_target_group.tg[2].arn
  }

  condition {
    path_pattern {
      values = ["/register*"]
    }
  }
}



