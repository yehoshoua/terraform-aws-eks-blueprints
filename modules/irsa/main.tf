resource "kubernetes_namespace_v1" "irsa" {
  count = var.create_kubernetes_namespace && var.kubernetes_namespace != "kube-system" ? 1 : 0

  metadata {
    name = var.kubernetes_namespace
  }
}

resource "kubernetes_service_account_v1" "irsa" {
  count = var.create_kubernetes_service_account ? 1 : 0

  metadata {
    name        = var.kubernetes_service_account
    namespace   = var.kubernetes_namespace
    annotations = var.irsa_iam_policies != null ? { "eks.amazonaws.com/role-arn" : aws_iam_role.irsa[0].arn } : null
  }

  automount_service_account_token = true
}


data "aws_iam_policy_document" "assume_role" {
  count = length(var.irsa_iam_policies) > 0 ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.addon_context.eks_oidc_provider_arn]
    }

    condition {
      test     = "StringLike"
      variable = "${var.addon_context.eks_oidc_issuer_url}:sub"
      values   = ["system:serviceaccount:${var.kubernetes_namespace}:${var.kubernetes_service_account}"]
    }
  }
}

resource "aws_iam_role" "irsa" {
  count = length(var.irsa_iam_policies) > 0 ? 1 : 0

  name        = try(var.addon_context.iam_role_name, "${var.addon_context.eks_cluster_id}-${trim(var.kubernetes_service_account, "-*")}-irsa")
  description = "AWS IAM Role for the Kubernetes service account ${var.kubernetes_service_account}."
  path        = var.addon_context.irsa_iam_role_path

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Federated" : "${var.addon_context.eks_oidc_provider_arn}"
        },
        "Action" : "sts:AssumeRoleWithWebIdentity",
        "Condition" : {
          "StringLike" : {
            "${var.addon_context.eks_oidc_issuer_url}:sub" : "system:serviceaccount:${var.kubernetes_namespace}:${var.kubernetes_service_account}"
          }
        }
      }
    ]
  })

  force_detach_policies = true
  permissions_boundary  = var.addon_context.irsa_iam_permissions_boundary

  tags = var.addon_context.tags
}

resource "aws_iam_role_policy_attachment" "irsa" {
  count = length(var.irsa_iam_policies)

  policy_arn = var.irsa_iam_policies[count.index]
  role       = aws_iam_role.irsa[0].name
}
