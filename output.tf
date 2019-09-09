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
