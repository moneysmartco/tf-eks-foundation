#----------------------
# Basic
#----------------------
variable "project_name" {
  default = ""
}

variable "env" {
  default = ""
}

variable "vpc_id" {}
variable "private_subnet_ids" {}
variable "public_subnet_ids" {}
variable "bastion_security_gp" {}

#------------------------------------------
# Tagging
#------------------------------------------
variable "tags" {
  description = "Tagging resources with default values"

  default = {
    "Name"        = ""
    "Country"     = ""
    "Environment" = ""
    "Repository"  = ""
    "Owner"       = ""
    "Department"  = ""
    "Team"        = "shared"
    "Product"     = "common"
    "Project"     = "common"
    "Stack"       = ""
  }
}

locals {
  # env tag in map structure
  env_tag = {
    Environment = "${var.env}"
  }

  # AWS-required k8s tag in map structure
  k8s_tag = {
    "kubernetes.io/cluster/${var.project_name}-${var.env}" = "owned"
  }

  # ec2 security group name tag in map structure
  control_plane_security_group_name_tag = {
    Name = "${var.project_name}-${var.env}-eks-control-plane-sg"
  }

  worker_node_security_group_name_tag = {
    Name = "${var.project_name}-${var.env}-eks-worker-sg"
  }

  #------------------------------------------------------------
  # variables that will be mapped to the various resource block
  #------------------------------------------------------------
  control_plane_security_group_tags = "${merge(var.tags, local.k8s_tag, local.env_tag, local.control_plane_security_group_name_tag)}"

  worker_node_security_group_tags = "${merge(var.tags, local.k8s_tag, local.env_tag, local.worker_node_security_group_name_tag)}"
}
