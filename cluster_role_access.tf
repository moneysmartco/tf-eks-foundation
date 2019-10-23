## IAM Role for EKS cluster access
## - admin
## - read-only access with kubectl exec
resource "aws_iam_role" "eks_cluster_admin" {
  # IAM role prefix is 32 characters max
  name_prefix = "${replace(format("%s-%s-admin", var.project_name, var.env), "/(.{0,31})(.*)/", "$1-")}"
  description = "IAM role for admin access in ${var.project_name}-${var.env} EKS cluster"

  max_session_duration = "${var.cluster_role_max_session_duration}"

  assume_role_policy = "${data.aws_iam_policy_document.assume_role_trust_policy.json}"
}

resource "aws_iam_role" "eks_cluster_readonly" {
  # IAM role prefix is 32 characters max
  name_prefix = "${replace(format("%s-%s-readonly", var.project_name, var.env), "/(.{0,31})(.*)/", "$1-")}"
  description = "IAM role for readonly access in ${var.project_name}-${var.env} EKS cluster"

  max_session_duration = "${var.cluster_role_max_session_duration}"

  assume_role_policy = "${data.aws_iam_policy_document.assume_role_trust_policy.json}"
}

#------------------------------------------------------------------
# Role policy document to set assume role trusted relationships
#------------------------------------------------------------------
data "aws_iam_policy_document" "assume_role_trust_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    # Allow anyone from ${aws_account_id} to access
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.aws_account_id}:root"]
    }

    # Use MFA
    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["true"]
    }
  }
}

#----------------------------------------------
# Policy for listing cluster
#----------------------------------------------
data "template_file" "eks_get_token_policy" {
  template = "${file("${path.module}/templates/EKSGetToken.json")}"
}

resource "aws_iam_policy" "eks_get_token_policy" {
  name_prefix = "${replace(format("eks-access-%s-%s", var.project_name, var.env), "/(.{0,31})(.*)/", "$1-")}"
  description = "EKS policy for fetching token from ${var.project_name}-${var.env} cluster"

  policy = "${data.template_file.eks_get_token_policy.rendered}"
}

resource "aws_iam_role_policy_attachment" "get_token_policy_to_admin" {
  policy_arn = "${aws_iam_policy.eks_get_token_policy.arn}"
  role       = "${aws_iam_role.eks_cluster_admin.name}"
}

resource "aws_iam_role_policy_attachment" "get_token_policy_to_readonly" {
  policy_arn = "${aws_iam_policy.eks_get_token_policy.arn}"
  role       = "${aws_iam_role.eks_cluster_readonly.name}"
}

#----------------------------------------------
# IAM Group for assume role access
#----------------------------------------------
resource "aws_iam_group" "eks_cluster_admin_group" {
  name = "${format("%s-%s-admin", var.project_name, var.env)}"
  path = "/"
}

resource "aws_iam_group_policy_attachment" "eks_cluster_admin_group_policy_attachment" {
  group      = "${aws_iam_group.eks_cluster_admin_group.name}"
  policy_arn = "${aws_iam_policy.assume_admin_role_policy.arn}"
}

resource "aws_iam_group" "eks_cluster_readonly_group" {
  name = "${format("%s-%s-readonly", var.project_name, var.env)}"
  path = "/"
}

resource "aws_iam_group_policy_attachment" "eks_cluster_readonly_group_policy_attachment" {
  group      = "${aws_iam_group.eks_cluster_readonly_group.name}"
  policy_arn = "${aws_iam_policy.assume_readonly_role_policy.arn}"
}

#----------------------------------------------
# Policy for assume role access on group
#----------------------------------------------
data "aws_iam_policy_document" "assume_admin_role_policy" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    resources = ["${aws_iam_role.eks_cluster_admin.arn}"]
  }
}

resource "aws_iam_policy" "assume_admin_role_policy" {
  name = "${format("%s-%s-admin-switch-role", var.project_name, var.env)}"
  path   = "/"
  policy = "${data.aws_iam_policy_document.assume_admin_role_policy.json}"
}

data "aws_iam_policy_document" "assume_readonly_role_policy" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    resources = ["${aws_iam_role.eks_cluster_readonly.arn}"]
  }
}

resource "aws_iam_policy" "assume_readonly_role_policy" {
  name = "${format("%s-%s-readonly-switch-role", var.project_name, var.env)}"
  path   = "/"
  policy = "${data.aws_iam_policy_document.assume_readonly_role_policy.json}"
}


#----------------------------------------------
# Add users to groups
#----------------------------------------------
resource "aws_iam_group_membership" "eks_cluster_admin_group_membership" {
  name = "${format("%s-%s-admin-membership", var.project_name, var.env)}"

  users = "${var.eks_cluster_admin_group_member}"

  group = "${aws_iam_group.eks_cluster_admin_group.name}"
}

resource "aws_iam_group_membership" "eks_cluster_readonly_group_membership" {
  name = "${format("%s-%s-readonly-membership", var.project_name, var.env)}"

  users = "${var.eks_cluster_readonly_group_member}"

  group = "${aws_iam_group.eks_cluster_readonly_group.name}"
}