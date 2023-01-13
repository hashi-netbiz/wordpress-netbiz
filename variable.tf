variable "aws_network_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "aws_pub_subnet_1_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "aws_pub_subnet_2_cidr" {
  type    = string
  default = "10.0.2.0/24"
}

variable "aws_wp_subnet_cidr" {
  type    = string
  default = "10.0.101.0/24"
}

variable "aws_db_subnet_1_cidr" {
  type    = string
  default = "10.0.201.0/24"
}

variable "aws_db_subnet_2_cidr" {
  type    = string
  default = "10.0.202.0/24"
}

variable "aws_wp_db_user" {
  type    = string
}

variable "aws_wp_db_password" {
  type    = string  
}

variable "aws_instance_type" {
  default = "t2.micro"
}

variable "key_pair_name" {
  default = "nmap"
}

variable "dbName" {
  default = "netbiz_db"
}