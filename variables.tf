# ------------------------------------------------------------
# variables.tf
# The "inputs" of our project. Values are filled in terraform.tfvars.
# ------------------------------------------------------------

variable "region" {
  description = "AWS region (Mumbai)"
  type        = string
  default     = "ap-south-1"
}

variable "my_ip" {
  description = "Your laptop's public IP + /32. Only this IP may SSH into the bastion. Find it with: curl ifconfig.me"
  type        = string
}

variable "key_name" {
  description = "Name of an EC2 key pair that already exists in ap-south-1"
  type        = string
}

variable "private_key_path" {
  description = "Where that key pair's .pem file is on this machine (Ansible uses it to log in)"
  type        = string
}

variable "instance_type" {
  description = "Size of the two monitoring servers"
  type        = string
  default     = "t3.small"
}
