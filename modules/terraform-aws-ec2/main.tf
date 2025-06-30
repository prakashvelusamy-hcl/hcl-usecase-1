resource "aws_instance" "public_instances" {
  count         = var.public_instance
  ami           = "ami-0e35ddab05955cf57"
  instance_type = "t3.micro"
  subnet_id     = var.public_subnet_ids[count.index]
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y nginx
              systemctl start nginx
              systemctl enable nginx
              echo "<h1>This is my default server </h1>" > /var/www/html/index.html
              mkdir -p /var/www/html/image
              echo "<h1> This is my image server </h1>" > /var/www/html/image/index.html
              mkdir -p /var/www/html/register
              echo "<h1> This is my register server </h1>" > /var/www/html/register/index.html
              systemctl reload nginx
              EOF
  tags = {
    Name = "Public-Instance-${count.index}"
  }
}





