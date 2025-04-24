resource "aws_eks_cluster" "eks" {
  name     = local.cluster_name
  version  = local.eks_version
  role_arn = aws_iam_role.eks_server_role.arn

  vpc_config {
    endpoint_private_access = false
    endpoint_public_access  = true

    subnet_ids = [
      for subnet in aws_subnet.private_zone : subnet.id
    ]
  }

  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }

  depends_on = [aws_iam_role_policy_attachment.eks_server_policy]

  timeouts {
    create = "30m"
    delete = "30m"
  }
}

resource "aws_eks_node_group" "eks_node_group" {
  cluster_name    = aws_eks_cluster.eks.name
  version         = aws_eks_cluster.eks.version
  node_group_name = "${local.cluster_name}-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn

  subnet_ids = [for subnet in aws_subnet.private_zone : subnet.id]

  capacity_type  = "ON_DEMAND"
  instance_types = ["t3.large"]

  scaling_config {
    desired_size = 1
    max_size     = 10
    min_size     = 0
  }

  labels = {
    role = "general"
  }

  depends_on = [aws_iam_role_policy_attachment.eks_node_policy]

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }

  timeouts {
    create = "30m"
    delete = "30m"
  }
}
