# # Create Random Pet Resource
resource "random_pet" "this" {
  length = 1
  prefix = "hashi" 
}

locals {
  ec2_key_name = random_pet.this.id
}

data "aws_ami" "ubuntu" {
    #most_recent = true
 
    filter {
        name   = "name"
        #values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
        values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-20221212"]
    }
 
    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }
 
    filter {
        name   = "architecture"
        values = ["x86_64"]
    }
}

#provision wordpress subnet
resource "aws_subnet" "wp_subnet" {
  vpc_id = "${aws_vpc.app_vpc.id}"
  cidr_block = "${var.aws_wp_subnet_cidr}"
  tags = {
    Name = "WordPress subnet"
  }
  availability_zone = "${data.aws_availability_zones.available.names[0]}"
}

# WP subnet routes for NAT
resource "aws_route_table" "wp-subnet-routes" {
    vpc_id = "${aws_vpc.app_vpc.id}"
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = "${aws_nat_gateway.nat-gw.id}"
    }

    tags = {
        Name = "web-subnet-routes-1"
    }
}
resource "aws_route_table_association" "wp-subnet-routes" {
    subnet_id = "${aws_subnet.wp_subnet.id}"
    route_table_id = "${aws_route_table.wp-subnet-routes.id}"
}

### SECURITY GROUPS #########################

#Private access for WP subnet
resource "aws_security_group" "wp" {
  name = "wp-secgroup"
  vpc_id = "${aws_vpc.app_vpc.id}"

  # ssh access from bastion
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["${var.aws_pub_subnet_1_cidr}"]
  }
  
  # msql access
  ingress {
    from_port = 3306
    to_port   = 3306
    protocol  = "tcp"
    cidr_blocks = [
      "${var.aws_db_subnet_1_cidr}",    # db subnet 1
      "${var.aws_db_subnet_2_cidr}", # db subnet 2     
    ]
  }

  # http access from load balancer
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["${var.aws_pub_subnet_1_cidr}"]
  }

  egress {
    protocol = "-1"
    from_port = 0
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# WP SERVERS ############################
resource "aws_instance" "wp" {
  ami = "${data.aws_ami.ubuntu.id}"
  vpc_security_group_ids = [
    "${aws_security_group.wp.id}"
  ]
  count = 2
  instance_type = "${var.aws_instance_type}"
  subnet_id = "${aws_subnet.wp_subnet.id}"

  #key_name = "${aws_key_pair.demo_keys.key_name}"
  key_name = local.ec2_key_name

  tags = {
    Name = "wp-server-${count.index}"
    SELECTOR = "wp"
  }
}

resource "tls_private_key" "generated" {
  algorithm = "RSA"
}

resource "local_file" "private_key_pem" {
  content  = tls_private_key.generated.private_key_pem
  filename = "${local.ec2_key_name}.pem"
}

resource "aws_key_pair" "mykeypair" {
  key_name = local.ec2_key_name
  public_key = tls_private_key.generated.public_key_openssh
}

resource "null_resource" "wp_provisioner" {
  triggers = {
    wp_instance = "${element(aws_instance.wp.*.private_ip, count.index)}",
    rds_endpoint = aws_db_instance.wp-db.endpoint
  }

  provisioner "file" {
    source      = "scripts/init_wp.sh"
    destination = "/tmp/init_wp.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/init_wp.sh",
      #"/tmp/init_wp.sh ${aws_db_instance.wp-db.address} ${var.aws_wp_db_user} ${var.aws_wp_db_password}",
      "/tmp/init_wp.sh ${var.aws_wp_db_user} ${var.aws_wp_db_password} ${var.dbName} ${aws_db_instance.wp-db.endpoint}",
    ]
  }
    # db_username=$1 #db_username
    # db_user_password=$2 #db_user_password
    # db_name=$3 #db_name
    # db_RDS=$4 #db_RDS

  connection {
    type                = "ssh"
    private_key         = "${tls_private_key.generated.private_key_pem}"
    host                = "${element(aws_instance.wp.*.private_ip, count.index)}"
    user                = "ubuntu"
    bastion_host        = "${aws_eip.bastion_eip.public_ip}"
    bastion_private_key = "${tls_private_key.generated.private_key_pem}"
    bastion_user        = "ubuntu"
    timeout             = "30s"
  }
  depends_on = [aws_eip_association.bastion_eip_assoc, aws_instance.wp]
  count = 2
}