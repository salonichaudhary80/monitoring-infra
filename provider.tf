# ------------------------------------------------------------
# provider.tf
# Tells Terraform: "we are using AWS, in the Mumbai region".
# ------------------------------------------------------------

terraform {
  required_version = ">= 1.4" # needed for terraform_data (ansible.tf)

  required_providers {
    aws = {
      source  = "hashicorp/aws" # plugin that talks to AWS
      version = "~> 5.0"
    }
    local = {
      source  = "hashicorp/local" # plugin that writes a file on your laptop (the Ansible inventory)
      version = "~> 2.5"
    }
  }
}

provider "aws" {
  region = var.region # ap-south-1 = Mumbai
}
