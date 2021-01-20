terraform {
  required_version = ">= 0.13"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "3.22.0"
    }
    cloudinit = {
      source = "hashicorp/cloudinit"
      version = "2.1.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

provider "cloudinit" {
}

data "template_cloudinit_config" "config" {
  gzip = true
  base64_encode = true

  part {
    filename = var.cloud_config
    content_type = "text/x-shellscript"
    content = file(var.cloud_config)
  }

}

