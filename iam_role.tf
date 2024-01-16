#------------------------------------------
# Control Plane IAM role
#------------------------------------------
data "aws_iam_policy_document" "cluster_assume_role_policy" {
  statement {
    sid = "EKSClusterAssumeRole"

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eks_control_plane" {
  # IAM role prefix is 32 characters max
  name_prefix = replace(
    format("%s-%s-control", var.project_name, var.env),
    "/(.{0,31})(.*)/",
    "$1-",
  )
  assume_role_policy = data.aws_iam_policy_document.cluster_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "eks_cluster" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_control_plane.name
}

resource "aws_iam_role_policy_attachment" "eks_service" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks_control_plane.name
}

#------------------------------------------
# Worker Node IAM role
#------------------------------------------
data "aws_iam_policy_document" "workers_assume_role_policy" {
  statement {
    sid = "EKSWorkerAssumeRole"

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eks_worker" {
  # IAM role prefix is 32 characters max
  name_prefix = replace(
    format("%s-%s-worker", var.project_name, var.env),
    "/(.{0,31})(.*)/",
    "$1-",
  )
  assume_role_policy = data.aws_iam_policy_document.workers_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "workers_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_worker.name
}

resource "aws_iam_role_policy_attachment" "workers_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_worker.name
}

resource "aws_iam_role_policy_attachment" "workers_AmazonEKS_EBSCSIDriver_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.eks_worker.name
}

resource "aws_iam_role_policy_attachment" "workers_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_worker.name
}

resource "aws_iam_instance_profile" "worker" {
  name_prefix = "${var.project_name}-${var.env}-"
  role        = aws_iam_role.eks_worker.name
}

## For ALB Ingress Controller access
data "template_file" "alb_ingress_policy" {
  template = file(
    "${path.module}/templates/ALBIngressControllerIAMPolicy.json",
  )
}

resource "aws_iam_policy" "workers_alb_ingress_policy" {
  name_prefix = replace(
    format("worker-ingress-%s-%s", var.project_name, var.env),
    "/(.{0,31})(.*)/",
    "$1-",
  )
  description = "Worker node policy for ${var.project_name}-${var.env} cluster to access ALB ingress controller"

  policy = data.template_file.alb_ingress_policy.rendered
}

resource "aws_iam_role_policy_attachment" "workers_ALBIngressAccessPolicy" {
  policy_arn = aws_iam_policy.workers_alb_ingress_policy.arn
  role       = aws_iam_role.eks_worker.name
}

