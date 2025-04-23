locals {
  server_policies = [
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
  ]
  node_policies = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
  ]
}

resource "aws_iam_role" "eks_server_role" {
  name = "${local.cluster_name}-server-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole",
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_server_policy" {
  count      = length(local.server_policies)
  policy_arn = local.server_policies[count.index]
  role       = aws_iam_role.eks_server_role.name
}


resource "aws_iam_role" "eks_node_role" {
  name = "${local.cluster_name}-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_node_policy" {
  count      = length(local.node_policies)
  policy_arn = local.node_policies[count.index]
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_user" "developer_user" {
  name = "developer"
}

resource "aws_iam_policy" "developer_eks_policy" {
  name = "AmazonEKSDeveloperPolicy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "developer_user_policy" {
  user       = aws_iam_user.developer_user.name
  policy_arn = aws_iam_policy.developer_eks_policy.arn
}

resource "aws_eks_access_entry" "developer" {
  cluster_name      = aws_eks_cluster.eks.name
  principal_arn     = aws_iam_user.developer_user.arn
  kubernetes_groups = ["viewer-group"]
}

data "aws_caller_identity" "current" {

}

resource "aws_iam_role" "eks_admin_role" {
  name = "${local.cluster_name}-admin-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "eks_admin_policy" {
  name = "AmazonEKSAdminPolicy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow"
        Action   = "eks:*"
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = "iam:PassRole"
        Resource = "*"
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "eks.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_admin_role_policy" {
  role       = aws_iam_role.eks_admin_role.name
  policy_arn = aws_iam_policy.eks_admin_policy.arn
}

resource "aws_iam_user" "manager_user" {
  name = "manager"
}

resource "aws_iam_policy" "eks_assume_admin" {
  name = "AmazonEKSAssumeAdminPolicy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow"
        Action   = "sts:AssumeRole"
        Resource = aws_iam_role.eks_admin_role.arn
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "manager" {
  user       = aws_iam_user.manager_user.name
  policy_arn = aws_iam_policy.eks_assume_admin.arn
}

resource "aws_eks_access_entry" "manager" {
  cluster_name      = aws_eks_cluster.eks.name
  principal_arn     = aws_iam_role.eks_admin_role.arn
  kubernetes_groups = ["admin-group"]
}
