resource "aws_vpc" "myvpc" {
  cidr_block = var.cidr
}

resource "aws_subnet" "sub1" {
  vpc_id = aws_vpc.myvpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "sub2" {
  vpc_id = aws_vpc.myvpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id
}

resource "aws_route_table" "RT1" {
  vpc_id = aws_vpc.myvpc.id

  route{
    cidr_block = "0.0.0.0.0/0" #which means everything inside the vpc should connect to something
    gateway_id = aws_internet_gateway.igw.id
  }

}
resource "aws_route_table_association" "RTa1" {
  subnet_id = aws_subnet.sub1.id
  route_table_id = aws_route_table.RT1.id
}

resource "aws_route_table_association" "RTa2" {
  subnet_id = aws_subnet.sub2.id
  route_table_id = aws_route_table.RT1.id
}

resource "aws_security_group" "secGroup" {
  name = "sg"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"] #everyone can access this instance
  }
  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"] #everyone can access this instance
  }
  egress {
    from_port        = 0 //means all ports can access 
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg"
  }
}
resource "aws_s3_bucket" "mys3" {
  bucket = "terrafor-mwith-aws-project"

  tags = {
    Name = "my_bucket"
  }
}

resource "aws_instance" "server1" {
  ami = "ami-0fc5d935ebf8bc3bc"
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.secGroup.id]
  subnet_id = aws_subnet.sub1.id
  user_data = base64encode(file("userData.sh"))

}
resource "aws_instance" "server2" {
  ami = "ami-0fc5d935ebf8bc3bc"
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.secGroup.id]
  subnet_id = aws_subnet.sub2.id
  user_data = base64encode(file("userData1.sh"))

}

resource "aws_lb" "myalb" {
  name = "myalb"
  internal = false

  security_groups = [aws_security_group.secGroup]
  subnets = [aws_subnet.sub1.id, aws_subnet.sub2.id]

}

resource "aws_lb_target_group" "tg" {
  name = "mytg"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.myvpc.id

  #if the targets are not ready, transfer the traffic to / path
  health_check {
    path = "/"
    port = "traffic-port"
  }

}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.myalb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.tg.arn
    type             = "forward"
  }
}

resource "aws_lb_target_group_attachment" "attach1" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.server1.id
  port             = 80
}
resource "aws_lb_target_group_attachment" "attach2" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.server2.id
  port             = 80
}

output "loadbalancerdns" {
  value = aws_lb.myalb.dns_name
}
