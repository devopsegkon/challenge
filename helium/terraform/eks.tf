module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.29"

  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_endpoint_public_access  = var.cluster_endpoint_public_access
  cluster_endpoint_private_access = true

  eks_managed_node_groups = {
    default = {
      min_size       = 1
      max_size       = 2
      desired_size   = 2
      instance_types = [var.instance_type]
      capacity_type  = "ON_DEMAND"
    }
  }

  enable_irsa = true

  tags = {
    Environment = "dev"
  }
}

# Custom IAM Policy: RDS IAM DB Authentication (minimal for IAM auth)
resource "aws_iam_policy" "eks_pod_rds_iam_auth" {
  name_prefix = "EKS-RDS-IAM-Auth"
  description = "Allow EKS pods to use IAM DB authentication for Aurora"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "rds:DescribeDBClusters"
        Resource = "arn:aws:rds:us-east-1:067516285526:cluster:my-aurora-cluster"
      },
      {
        Effect   = "Allow"
        Action   = "rds-db:connect"
        Resource = "arn:aws:rds-db:us-east-1:067516285526:dbuser:cluster-*/dbadmin"
      }
    ]
  })
}

# Custom IAM Policy: Secrets Manager Access 
resource "aws_iam_policy" "eks_pod_secrets_manager" {
  name_prefix = "EKS-SecretsManager"
  description = "Allow EKS pods to read Aurora credentials"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
        Resource = aws_secretsmanager_secret.aurora_credentials.arn
      },
      {
        Effect   = "Allow"
        Action   = ["kms:Decrypt", "kms:DescribeKey"]
        Resource = aws_kms_key.secrets.arn
      }
    ]
  })
}

# IRSA Role for EKS Pods
module "eks_pod_iam_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "${var.cluster_name}-rds-access"

  #  Define OIDC trust
  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["client-ns:python-client-sa"]
    }
  }

}

# Attach Custom Policies to the IRSA Role (using native Terraform resources)
resource "aws_iam_role_policy_attachment" "rds_iam_auth" {
  role       = module.eks_pod_iam_role.iam_role_name
  policy_arn = aws_iam_policy.eks_pod_rds_iam_auth.arn
}

resource "aws_iam_role_policy_attachment" "secrets_access" {
  role       = module.eks_pod_iam_role.iam_role_name
  policy_arn = aws_iam_policy.eks_pod_secrets_manager.arn
}

resource "null_resource" "update_kubeconfig" {
  triggers = {
    cluster_id = module.eks.cluster_id
    cluster_endpoint = module.eks.cluster_endpoint
    cluster_ca = module.eks.cluster_certificate_authority_data
  }

  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${var.cluster_name} --region us-east-1 --alias ${var.cluster_name}"
  }

  depends_on = [
    module.eks
  ]
}
