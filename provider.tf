terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }

    random = {
      source = "hashicorp/random"
      version = "3.4.3"
    }

    tls = {
      source = "hashicorp/tls"
      version = "4.0.4"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}