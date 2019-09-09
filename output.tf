#------------------------------------------
# Security Groups
#------------------------------------------
output "control_plane_security_group_id" {
  value = "${aws_security_group.control_plane_sg.id}"
}

output "worker_node_security_group_id" {
  value = "${aws_security_group.worker_sg.id}"
}

#------------------------------------------
# IAM Roles
#------------------------------------------
output "control_plane_iam_role_arn" {
  value = "${aws_iam_role.eks_control_plane.arn}"
}

output "worker_node_instance_profile_name" {
  value = "${aws_iam_instance_profile.worker.name}"
}

#------------------------------------------
# EKS control plane
#------------------------------------------
output "eks_master_id" {
  value = "${aws_eks_cluster.master.id}"
}

output "eks_master_endpoint" {
  value = "${aws_eks_cluster.master.endpoint}"
}

output "eks_master_version" {
  value = "${aws_eks_cluster.master.version}"
}

output "eks_master_platform_version" {
  value = "${aws_eks_cluster.master.platform_version}"
}

output "eks_master_certificate_authority" {
  value = "${aws_eks_cluster.master.certificate_authority}"
}
