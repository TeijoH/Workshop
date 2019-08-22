//create AWS provider 
provider "aws" {
    //aws profile defined in aws cli
  profile    = "amplifyAdmin-1"

    //aws region selection
  region     = "ap-southeast-1"
}

//create s3 tfstate location 
terraform {
  backend "s3"{
    bucket         = "terraform-bucket-alevz"
    region         = "ap-southeast-1"
    key            = "terraform-state/terraform.tfstate"
    dynamodb_table = "terraform_state_lock"
  }
}


//create VPC 
resource "aws_vpc" "workshopvpc" {
  cidr_block       = "20.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = "true"
  tags = {
    Name = "workshop-vpc"
  }
}

//create Internet Gateway
resource "aws_internet_gateway" "igwWorkshop" {
  vpc_id = "${aws_vpc.workshopvpc.id}"

  tags = {
    Name = "igwWorkshop"
  }
}

//create public Subnet
resource "aws_subnet" "workshopPublicSubnet" {
  vpc_id     = "${aws_vpc.workshopvpc.id}"
  cidr_block = "20.0.1.0/24"
  map_public_ip_on_launch = "true"
  availability_zone = "ap-southeast-1a"
  tags = {
    Name = "workshopPublicSubnet"
  }
}

//create public Subnet for RDS
resource "aws_subnet" "workshopPublicSubnet2" {
  vpc_id     = "${aws_vpc.workshopvpc.id}"
  cidr_block = "20.0.2.0/24"
  map_public_ip_on_launch = "true"
  availability_zone = "ap-southeast-1b"
  tags = {
    Name = "workshopPublicSubnet2"
  }
}

//create Route Table with allocation to Internet Gateway
resource "aws_route_table" "routeTableWorkshop" {
  vpc_id = "${aws_vpc.workshopvpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igwWorkshop.id}"
  }

  tags = {
    Name = "routeTableWorkshop"
  }
}

//create association RouteTable to Subnet
resource "aws_route_table_association" "aRouteTableSubnet" {
  subnet_id      = "${aws_subnet.workshopPublicSubnet.id}"
  route_table_id = "${aws_route_table.routeTableWorkshop.id}"
}

resource "aws_route_table_association" "aRouteTableSubnet2" {
  subnet_id      = "${aws_subnet.workshopPublicSubnet2.id}"
  route_table_id = "${aws_route_table.routeTableWorkshop.id}"
}

//create Security Group Web + SSH
resource "aws_security_group" "secGroupWorkshopWebSSH" {
  name        = "secGroupWorkshopWebSSH"
  description = "Allow TLS inbound traffic"
  vpc_id      = "${aws_vpc.workshopvpc.id}"
  
  ingress {
    # TLS (change to whatever ports you need)
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    # Please restrict your ingress to only necessary IPs and ports.
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    # TLS (change to whatever ports you need)
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    # Please restrict your ingress to only necessary IPs and ports.
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    # TLS (change to whatever ports you need)
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    # Please restrict your ingress to only necessary IPs and ports.
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "secGroupWorkshopWebSSH"
  }
}

//create security group access MYSQL
resource "aws_security_group" "secGroupWorkshopMYSQL" {
  name        = "secGroupWorkshopMYSQL"
  description = "Allow TLS inbound traffic"
  vpc_id      = "${aws_vpc.workshopvpc.id}"
  
  ingress {
    # TLS (change to whatever ports you need)
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    # Please restrict your ingress to only necessary IPs and ports.
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    security_groups = ["${aws_security_group.secGroupWorkshopWebSSH.id}"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "secGroupWorkshopMYSQL"
  }
}

/*resource "aws_iam_role" "roleWorkshop" {
  name = "roleWorkshop"
  //path = "/"

  assume_role_policy = <<-EOF
                        {
                            "Version": "2012-10-17",
                            "Statement": [
                                {
                                    "Action": "ssm:*",
                                    "Resource": "arn:aws:ssm:*:*:parameter/inventory-app/*", 
                                    "Effect": "Allow"
                                }
                            ]
                        }
                        EOF
}*/

resource "aws_iam_instance_profile" "instanceProfileWorkshop" {
  name = "instanceProfileWorkshop"
  role = "Inventory-App-Role"
}

//create EC2-ec2WorkshopWebApp user data local variable
variable "userdataEC2" {
    type = "string"
    default  = <<-EOF
                #!/bin/bash
                yum install -y httpd mysql 
                amazon-linux-extras install -y php7.2 
                wget https://us-west-2-tcprod.s3.amazonaws.com/courses/ILT-TF-100-ARCHIT/v6.4.1/lab-2-webapp/scripts/inventory-app.zip 
                unzip inventory-app.zip -d /var/www/html/ 
                wget https://github.com/aws/aws-sdk-php/releases/download/3.62.3/aws.zip 
                unzip aws -d /var/www/html 
                chkconfig httpd on 
                service httpd start
                EOF
}

//create EC2 Apps
resource "aws_instance" "ec2WorkshopWebApp" {
    //aws AMI selection -- Amazon Linux 2
  ami           = "ami-0602ae7e6b9191aea"

    //aws EC2 instance type, t2.micro for free tier
  instance_type                 = "t2.micro"
  key_name                      = "testkeypair"
  subnet_id                     = "${aws_subnet.workshopPublicSubnet.id}"
  vpc_security_group_ids        = ["${aws_security_group.secGroupWorkshopWebSSH.id}"]
  //user_data_base64            = "${base64encode(var.userdataEC2)}"
  user_data                     = "${var.userdataEC2}"
  iam_instance_profile          =  "${aws_iam_instance_profile.instanceProfileWorkshop.name}"
  tags = {
    Name = "ec2WorkshopWebApp"
  }
}


# resource "aws_instance" "ec2WorkshopWebApp2" {
#     //aws AMI selection -- Amazon Linux 2
#   ami           = "ami-0602ae7e6b9191aea"

#     //aws EC2 instance type, t2.micro for free tier
#   instance_type                 = "t2.micro"
#   key_name                      = "testkeypair"
#   subnet_id                     = "${aws_subnet.workshopPublicSubnet.id}"
#   vpc_security_group_ids        = ["${aws_security_group.secGroupWorkshopWebSSH.id}"]
#   //user_data_base64            = "${base64encode(var.userdataEC2)}"
#   user_data                     = "${var.userdataEC2}"
#   iam_instance_profile          =  "${aws_iam_instance_profile.instanceProfileWorkshop.name}"
#   tags = {
#     Name = "ec2WorkshopWebApp2"
#   }
# }


// create DB Subnet Group -- Subnet1+Subnet2
resource "aws_db_subnet_group" "dbSubnetGroupWorkshop" {
  name       = "dbsubnetgroupworkshop"
  subnet_ids = ["${aws_subnet.workshopPublicSubnet.id}","${aws_subnet.workshopPublicSubnet2.id}"]

  tags = {
    Name = "dbSubnetGroupWorkshop"
  }
}


resource "aws_db_instance" "rdsWorkshop" {
  allocated_storage         = 20
  storage_type              = "gp2"
  engine                    = "mysql"
  engine_version            = "5.7"
  instance_class            = "db.t2.micro"
  name                      = "rdsWorkshop"
  username                  = "alevz"
  password                  = "Passw0rdDB"
  vpc_security_group_ids    = ["${aws_security_group.secGroupWorkshopMYSQL.id}"]
  db_subnet_group_name      = "${aws_db_subnet_group.dbSubnetGroupWorkshop.tags.Name}"
  parameter_group_name      = "default.mysql5.7"
  //backup_retention_period   = 1
  //snapshot_identifier = "some-snap"
  skip_final_snapshot = true
  publicly_accessible = true
  multi_az            = true
}

# resource "aws_db_instance" "rdsWorkshopReplica" {
#   allocated_storage         = 20
#   storage_type              = "gp2"
#   engine                    = "mysql"
#   engine_version            = "5.7"
#   instance_class            = "db.t2.micro"
#   name                      = "rdsWorkshopReplica"
#   username                  = "alevz"
#   password                  = "Passw0rdDB"
#   vpc_security_group_ids    = ["${aws_security_group.secGroupWorkshopMYSQL.id}"]
#   db_subnet_group_name      = "${aws_db_subnet_group.dbSubnetGroupWorkshop.tags.Name}"
#   parameter_group_name      = "default.mysql5.7"
#   //snapshot_identifier = "some-snap"
#   skip_final_snapshot = true
#   publicly_accessible = true
#   #multi_az            = true
#   replicate_source_db       = "${aws_db_instance.rdsWorkshop.id}"
# }

output "ip" {
  value = "${aws_instance.ec2WorkshopWebApp.public_ip}"
}

output "ip2" {
  value = "${aws_instance.ec2WorkshopWebApp2.public_ip}"
}

output "ipDB"{
    value = "${aws_db_instance.rdsWorkshop.address}"
}

# output "ipDBReplica"{
#     value = "${aws_db_instance.rdsWorkshopReplica.address}"
# }

output "dns"{
  value = "${aws_instance.ec2WorkshopWebApp.public_dns}"
}

output "dns2"{
  value = "${aws_instance.ec2WorkshopWebApp2.public_dns}"
}

output "userData"{
    value = "${var.userdataEC2}"
}