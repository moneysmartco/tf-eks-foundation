#----------------------
# Basic
#----------------------
variable "project_name" {
  default = ""
}

variable "env" {
  default = ""
}

variable "vpc_id" {
}

variable "private_subnet_ids" {
}

variable "public_subnet_ids" {
}

variable "bastion_security_gp" {
}

#------------------------------------------
# Cluster IAM Roles for access
#------------------------------------------
variable "aws_account_id" {
}

variable "cluster_role_max_session_duration" {
  description = "Session duration for STS token accessing EKS cluster (default: 12 hours)"
  default     = "43200"
}

variable "eks_cluster_admin_group_member" {
  description = "Users that will be added to the group to grant admin access to kubectl"
  type        = list(string)
  default     = []
}

variable "eks_cluster_readonly_group_member" {
  description = "Users that will be added to the group to grant readonly access to kubectl"
  type        = list(string)
  default     = []
}

#----------------------
# EKS master
#----------------------
variable "eks_master_cluster_log_types" {
  default = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "eks_master_endpoint_private_access" {
  default = true
}

variable "eks_master_endpoint_public_access" {
  default = true
}

variable "eks_master_platform_version" {
  default = "1.13"
}

#----------------------
# Cloudwatch Logs Group
#----------------------
variable "eks_master_log_retention_in_day" {
  default = "30"
}

#----------------------
# OIDC Role
#----------------------
variable "eks_master_oidc_thumbprints" {
  description = "Temporary variable for getting OIDC url ssl cert"
}

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
    Environment = var.env
  }

  # AWS-required k8s tag in map structure
  k8s_tag = {
    "kubernetes.io/cluster/${var.project_name}-${var.env}" = "owned"
  }

  # EKS cluster name tag in map structure
  control_plane_cluster_name_tag = {
    Name = "${var.project_name}-${var.env}"
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
  cloudwatch_log_group_tags = merge(var.tags, local.k8s_tag, local.env_tag)

  control_plane_cluster_group_tags = merge(
    var.tags,
    local.k8s_tag,
    local.env_tag,
    local.control_plane_cluster_name_tag,
  )
  control_plane_security_group_tags = merge(
    var.tags,
    local.k8s_tag,
    local.env_tag,
    local.control_plane_security_group_name_tag,
  )
  worker_node_security_group_tags = merge(
    var.tags,
    local.k8s_tag,
    local.env_tag,
    local.worker_node_security_group_name_tag,
  )
}

