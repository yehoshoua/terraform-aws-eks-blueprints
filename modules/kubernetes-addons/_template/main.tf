locals {
  name = "<TODO>"

  argocd_gitops_config = {
    enable             = true
    serviceAccountName = local.name
  }
}

module "helm_addon" {
  source = "../helm-addon"

  helm_config = merge({
    name        = local.name
    description = "<TODO>"
    chart       = local.name
    version     = "<TODO>"
    repository  = "<TODO>"
    namespace   = local.name
    values = [
      <<-EOT
      <REMOVE IF NOT USED>
      EOT
    ]
    },
    var.helm_config
  )

  set_values = [
    # If using IRSA, disable the helm chart from creating service account
    # and the module will create it instead. Update values below to suit.
    {
      name  = "serviceAccount.name"
      value = local.name
    },
    {
      name  = "serviceAccount.create"
      value = false
    }
  ]

  # Blueprints
  addon_context = var.addon_context

  # Remove if not using IRSA
  irsa_config = {
    kubernetes_namespace              = local.name
    kubernetes_service_account        = local.name
    create_kubernetes_namespace       = true
    create_kubernetes_service_account = true
    tags                              = var.addon_context.tags
    eks_cluster_id                    = var.addon_context.eks_cluster_id
    irsa_iam_policies                 = concat([aws_iam_policy.todo.arn], var.irsa_policies)
  }
}

# Remove if not using IRSA. Update permissions to suit
data "aws_iam_policy_document" "todo" {
  statement {
    actions = [
      "ec2:Describe*",
    ]

    resources = ["*"]
  }
}

# Remove if not using IRSA
resource "aws_iam_policy" "todo" {
  name        = "${var.addon_context.eks_cluster_id}-${local.name}"
  description = "<TODO>"
  policy      = data.aws_iam_policy_document.todo.json

  tags = var.addon_context.tags
}
