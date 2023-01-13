data "aws_availability_zones" "available" {}

### AWS VPC ####################################################################
# provision app vpc
resource "aws_vpc" "app_vpc" {
  cidr_block           = var.aws_network_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "WP Solution VPC"
  }
}

# create igw
resource "aws_internet_gateway" "app_igw" {
  vpc_id = aws_vpc.app_vpc.id
}

# add dhcp options
resource "aws_vpc_dhcp_options" "dns_resolver" {
  domain_name_servers = ["AmazonProvidedDNS"]
}

# associate dhcp with vpc
resource "aws_vpc_dhcp_options_association" "dns_resolver" {
  vpc_id          = aws_vpc.app_vpc.id
  dhcp_options_id = aws_vpc_dhcp_options.dns_resolver.id
}