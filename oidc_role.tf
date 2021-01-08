# Setup Iam Role-Service Account for cluster
resource "aws_iam_openid_connect_provider" "eks_cluster" {
  client_id_list = ["sts.amazonaws.com"]

  url = aws_eks_cluster.master.identity[0].oidc[0].issuer

  # TODO: Need to obtain thumbprint of url manually, until following issue resolved
  # https://github.com/terraform-providers/terraform-provider-tls/issues/52
  # https://github.com/terraform-providers/terraform-provider-aws/pull/10217
  #
  # Doc: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc_verify-thumbprint.html
  thumbprint_list = split(",", var.eks_master_oidc_thumbprints)
}

data "aws_iam_policy_document" "eks_cluster_oidc_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test = "StringEquals"
      variable = "${replace(
        aws_iam_openid_connect_provider.eks_cluster.url,
        "https://",
        "",
      )}:sub"
      values = ["system:serviceaccount:kube-system:aws-node"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks_cluster.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "eks_cluster_oidc" {
  assume_role_policy = data.aws_iam_policy_document.eks_cluster_oidc_assume_role_policy.json
  name_prefix = replace(
    format("%s-%s-oidc", var.project_name, var.env),
    "/(.{0,31})(.*)/",
    "$1-",
  )

  description = "OIDC policy for ${var.project_name}-${var.env} cluster to assume roles by pods"
}

