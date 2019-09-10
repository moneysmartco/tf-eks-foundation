## IAM Role for EKS cluster access
## - admin
## - read-only access with kubectl exec
resource "aws_iam_role" "eks_cluster_admin" {
  # IAM role prefix is 32 characters max
  name_prefix = "${replace(format("%s-%s-admin", var.project_name, var.env), "/(.{0,31})(.*)/", "$1-")}"
  description = "IAM role for admin access in ${var.project_name}-${var.env} EKS cluster"

  assume_role_policy = "${data.aws_iam_policy_document.aws_user_assume_role_policy.json}"
}

resource "aws_iam_role" "eks_cluster_readonly" {
  # IAM role prefix is 32 characters max
  name_prefix = "${replace(format("%s-%s-readonly", var.project_name, var.env), "/(.{0,31})(.*)/", "$1-")}"
  description = "IAM role for readonly access in ${var.project_name}-${var.env} EKS cluster"

  assume_role_policy = "${data.aws_iam_policy_document.aws_user_assume_role_policy.json}"
}

#----------------------------------------------
# Role policy document for aws user to assume
#----------------------------------------------
data "aws_iam_policy_document" "aws_user_assume_role_policy" {
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
