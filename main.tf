# Multiple Website Hosting
# OBJECTIVE
# Launch a simple web server in a load balanced and highly available manner utilizing automation
# and AWS best practices. This web server should be able to serve two different websites.
#
# DELIVERABLES
# A single file template for either CloudFormation or Terraform which achieves the requirements
# listed below. Template file (or URL to the template) should be emailed back to the Onica point of
# contact by the set deadline.
#
# REQUIREMENTS
# Create a single file template which accomplishes the following:
# • Create a VPC with private / public subnets and all required dependent infrastructure. "Code Block lines 55-206"
# • Create an ELB to be used to register web server instances. "Code block lines 333 - 375"
# • Auto Scaling Group and Launch Configuration that launches EC2 instances and registers
# them to the ELB. "Code Block lines 264-331"
# • Security Group allowing HTTP traffic to load balancer from anywhere (not directly to the
# instances). "Code Block lines 209-232"
# • Security Group allowing only HTTP traffic from the load balancer to the instances. "Code Block lines 234-262"
# • Some kind of automation or scripting that achieves the following: "Code Block lines 264-331"
#   • Install and configure webserver
#     • Webserver must handle two different domains:
#       • www.test.com must respond with ‘hello test’
#       • ww2.test.com must respond with ‘hello test2’
#
# AMI to be used must be ‘standard’ AWS AMIs. Acceptable AMIs to use (us-west-2):
# • ami-e251209a – Amazon Linux
# • ami-db710fa3 – Ubuntu
# • ami-3703414f – Windows 2016 Base
# Equivalent AMI’s may be used in other regions if your project is region specific.
#
# SUCCESS CRITERIA
# The final test will be running these two curl commands:
# curl -H "Host: www.test.com" http://name-of-elb-endpoint-here
# curl -H "Host: ww2.test.com" http://name-of-elb-endpoint-here
# Those two commands should spit out 'hello test' and 'hello test2' respectively.
# If the servers are terminated, the autoscaling group should replace them and configure them
# appropriately without any interaction.
#
#################################################################################
#################################################################################
#################################################################################

terraform {
  required_version = "~> 0.11.13"
}

provider "aws" {
  region = "ca-central-1"
  profile = "default"
}

## VPC #########################################################################

resource "aws_vpc" "flavio-vpc" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = {
      Name = "flavio-vpc",
      Project = "Flavio-Onica"
  }
}

## PUBLIC SUBNETS ##############################################################

resource "aws_subnet" "public-1a" {
  vpc_id            = "${aws_vpc.flavio-vpc.id}"
  cidr_block        = "10.0.0.0/24"
  availability_zone = "ca-central-1a"
  tags {
    Name = "flavio-public-1a",
    Project = "Flavio-Onica"
  }
}

resource "aws_subnet" "public-1b" {
  vpc_id            = "${aws_vpc.flavio-vpc.id}"
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ca-central-1b"
  tags {
    Name = "flavio-public-1b",
    Project = "Flavio-Onica"
  }
}

resource "aws_internet_gateway" "flavio-igw" {
  vpc_id = "${aws_vpc.flavio-vpc.id}"
  tags {
    Name = "flavio-igw",
    Project = "Flavio-Onica"
  }
}

resource "aws_route_table" "public" {
  vpc_id           = "${aws_vpc.flavio-vpc.id}"
  tags {
    Name = "public-rtb",
    Project = "Flavio-Onica"
  }
}

resource "aws_route" "internet_through_internet_gateway" {
  route_table_id         = "${aws_route_table.public.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.flavio-igw.id}"
}

resource "aws_route_table_association" "public-1a" {
  count          = 2
  subnet_id      = "${element(aws_subnet.public-1a.*.id, count.index)}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_route_table_association" "public-1b" {
  count          = 2
  subnet_id      = "${element(aws_subnet.public-1b.*.id, count.index)}"
  route_table_id = "${aws_route_table.public.id}"
}

## PRIVATE SUBNETS #############################################################


resource "aws_eip" "nat_gateway-1a" {
  vpc   = true
}

resource "aws_eip" "nat_gateway-1b" {
  vpc   = true
}

resource "aws_nat_gateway" "nat-1a" {
  allocation_id = "${element(aws_eip.nat_gateway-1a.*.id, count.index)}"
  subnet_id     = "${element(aws_subnet.public-1a.*.id, count.index)}"
  tags {
    Name = "flavio-nat-1a"
  }
}

resource "aws_nat_gateway" "nat-1b" {
  allocation_id = "${element(aws_eip.nat_gateway-1b.*.id, count.index)}"
  subnet_id     = "${element(aws_subnet.public-1b.*.id, count.index)}"
  tags {
    Name = "flavio-nat-1b"
  }
}
resource "aws_subnet" "private-1a" {
  vpc_id            = "${aws_vpc.flavio-vpc.id}"
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ca-central-1a"
  tags {
    Name = "flavio-private-1a",
    Project = "Flavio-Onica"
  }
}

resource "aws_subnet" "private-1b" {
  vpc_id            = "${aws_vpc.flavio-vpc.id}"
  cidr_block        = "10.0.3.0/24"
  availability_zone = "ca-central-1b"
  tags {
    Name = "flavio-private-1b",
    Project = "Flavio-Onica"
  }
}

resource "aws_route_table" "private-1a" {
  vpc_id           = "${aws_vpc.flavio-vpc.id}"
  tags {
    Name = "flavio-rtb-1a",
    Project = "Flavio-Onica"
  }
}

resource "aws_route" "internet_through_nat_gateway-1a" {
  route_table_id         = "${element(aws_route_table.private-1a.*.id, count.index)}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${element(aws_nat_gateway.nat-1a.*.id, count.index)}"
}

resource "aws_route" "internet_through_nat_gateway-1b" {
  route_table_id         = "${element(aws_route_table.private-1b.*.id, count.index)}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${element(aws_nat_gateway.nat-1b.*.id, count.index)}"
}

resource "aws_route_table" "private-1b" {
  vpc_id           = "${aws_vpc.flavio-vpc.id}"
  tags {
    Name = "flavio-rtb-1b",
    Project = "Flavio-Onica"
  }
}

resource "aws_route_table_association" "private-1a" {
  subnet_id      = "${element(aws_subnet.private-1a.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.private-1a.*.id, count.index)}"
}

resource "aws_route_table_association" "private-1b" {
  subnet_id      = "${element(aws_subnet.private-1b.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.private-1b.*.id, count.index)}"
}


##### SG ####################

resource "aws_security_group" "flavio-web-sg" {
  name        = "flavio-web-sg"
  description = "flavio-web-sg"
  vpc_id = "${aws_vpc.flavio-vpc.id}"
  ingress {
    from_port = 80
    to_port = 80
    protocol = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
    egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

    tags                 = {
      Name = "flavio-web-sg",
      Project = "Flavio-Onica"
  }
}

resource "aws_security_group" "flavio-priv-sg" {
  name        = "flavio-priv-sg"
  description = "flavio-priv-sg"
  vpc_id = "${aws_vpc.flavio-vpc.id}"

  tags                 = {
      Name = "flavio-priv-sg",
      Project = "Flavio-Onica"
  }
}

resource "aws_security_group_rule" "flavio-priv-sg-in" {
  security_group_id = "${aws_security_group.flavio-priv-sg.id}"
  type = "ingress"
  from_port = 80
  to_port = 80
  protocol = "TCP"
  source_security_group_id = "${aws_security_group.flavio-web-sg.id}"
}

resource "aws_security_group_rule" "flavio-priv-sg-out" {
  security_group_id = "${aws_security_group.flavio-priv-sg.id}"
  type = "egress" 
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  
}

###### Launch Configuration and Auto scaling #######################

resource "aws_launch_configuration" "as_conf" {
  name_prefix   = "flavio-lc"
  image_id      = "ami-03338e1f67dae0168"
  instance_type = "t2.micro"
  security_groups = ["${aws_security_group.flavio-priv-sg.id}"]
  user_data = <<_END
#!/bin/bash
yum update -y
yum install httpd -y
systemctl enable httpd.service
mkdir -p /var/www/www.test.com/public_html
mkdir -p /var/www/ww2.test.com/public_html
chmod -R 755 /var/www
echo "hello test" > /var/www/www.test.com/public_html/index.html
echo "hello test2" > /var/www/ww2.test.com/public_html/index.html
mkdir /etc/httpd/sites-available
mkdir /etc/httpd/sites-enabled
echo "IncludeOptional sites-enabled/*.conf" >>  /etc/httpd/conf/httpd.conf
cat > /etc/httpd/sites-available/www.test.com.conf <<-EOF
<VirtualHost *:80>

    ServerName www.test.com
    ServerAlias www.test.com
    DocumentRoot /var/www/www.test.com/public_html
    ErrorLog /var/www/www.test.com/error.log
    CustomLog /var/www/www.test.com/requests.log combined
</VirtualHost>
EOF

cat > /etc/httpd/sites-available/ww2.test.com.conf <<-EOF
<VirtualHost *:80>

    ServerName ww2.test.com
    ServerAlias ww2.test.com
    DocumentRoot /var/www/ww2.test.com/public_html
    ErrorLog /var/www/ww2.test.com/error.log
    CustomLog /var/www/ww2.test.com/requests.log combined
</VirtualHost>
EOF

ln -s /etc/httpd/sites-available/www.test.com.conf /etc/httpd/sites-enabled/www.test.com.conf
ln -s /etc/httpd/sites-available/ww2.test.com.conf /etc/httpd/sites-enabled/ww2.test.com.conf
service httpd restart

    
  _END

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "flavio_ag" {
  name                      = "flavio-ag"
  max_size                  = 2
  min_size                  = 2
  health_check_grace_period = 300
  desired_capacity          = 2
  force_delete              = true
  launch_configuration      = "${aws_launch_configuration.as_conf.name}"
  vpc_zone_identifier       = ["${aws_subnet.private-1a.id}", "${aws_subnet.private-1b.id}"]

  timeouts {
    delete = "15m"
  }
}

##### Load Balance and target group #################

resource "aws_lb" "alb" {
  name               = "flavio-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.flavio-web-sg.id}"]
  subnets            = ["${aws_subnet.public-1a.id}","${aws_subnet.public-1b.id}"]
  enable_cross_zone_load_balancing  = true
  tags {
    Name = "flavio-alb",
    Project = "Flavio-Onica"
  }
}

resource "aws_lb_target_group" "nlb_target_group" {  
  name     = "elb-target-group"  
  port     = "80"  
  protocol = "HTTP"  
  vpc_id   = "${aws_vpc.flavio-vpc.id}"   
  tags {    
    name = "elb_target_group",
    Project = "Flavio-Onica"
  }     
}

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = "${aws_lb.alb.arn}"
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.nlb_target_group.arn}"
  } 
}

 

resource "aws_autoscaling_attachment" "nlb_autoscale" {
  alb_target_group_arn   = "${aws_lb_target_group.nlb_target_group.arn}"
  autoscaling_group_name = "${aws_autoscaling_group.flavio_ag.id}"
}


output "lb_address" {
  value = <<EOF
      "${aws_lb.alb.dns_name}
      
      SUCCESS CRITERIA
       The final test will be running these two curl commands:
        curl -H "Host: www.test.com" http://${aws_lb.alb.dns_name}
        curl -H "Host: ww2.test.com" http://${aws_lb.alb.dns_name}
        Those two commands should spit out 'hello test' and 'hello test2' respectively.
        If the servers are terminated, the autoscaling group should replace them and configure them
        appropriately without any interaction.
      "
    EOF
}