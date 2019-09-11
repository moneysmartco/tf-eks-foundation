resource "aws_eks_cluster" "master" {
  name = "${var.project_name}-${var.env}"

  version  = "${var.eks_master_platform_version}"
  role_arn = "${aws_iam_role.eks_control_plane.arn}"

  enabled_cluster_log_types = "${var.eks_master_cluster_log_types}"

  vpc_config = {
    subnet_ids              = "${concat(split(",", var.public_subnet_ids), split(",", var.private_subnet_ids))}"
    security_group_ids      = ["${aws_security_group.control_plane_sg.id}"]
    endpoint_private_access = "${var.eks_master_endpoint_private_access}"
    endpoint_public_access  = "${var.eks_master_endpoint_public_access}"
  }

  depends_on = ["aws_cloudwatch_log_group.eks_master_log"]
}

# Logging
resource "aws_cloudwatch_log_group" "eks_master_log" {
  name = "/aws/eks/${var.project_name}-${var.env}/cluster"

  retention_in_days = "${var.eks_master_log_retention_in_day}"

  tags = "${local.cloudwatch_log_group_tags}"
}
