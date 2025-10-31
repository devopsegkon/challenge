resource "aws_kms_key" "aurora" {
  description             = "KMS key for Aurora PostgreSQL encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "Enable IAM User Permissions"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "Allow RDS Service"
        Effect    = "Allow"
        Principal = { Service = "rds.amazonaws.com" }
        Action = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
        ]
        Resource  = "*"
      }
    ]
  })

  tags = { Name = "aurora-kms-key" }
}

resource "aws_kms_alias" "aurora" {
  name          = "alias/aurora-encryption-key"
  target_key_id = aws_kms_key.aurora.key_id
}

resource "aws_kms_key" "secrets" {
  description             = "KMS key for Secrets Manager"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "Enable IAM User Permissions"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "Allow Secrets Manager Service"
        Effect    = "Allow"
        Principal = { Service = "secretsmanager.amazonaws.com" }
        Action = [
          "kms:GenerateDataKey",
          "kms:Decrypt"
        ]
        Resource  = "*"
      },
      {
        Sid       = "Allow EKS Pods via IRSA"
        Effect    = "Allow"
        Principal = { AWS = module.eks_pod_iam_role.iam_role_arn }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource  = "*"
      }
    ]
  })

  tags = { Name = "secrets-kms-key" }
}

resource "aws_kms_alias" "secrets" {
  name          = "alias/secrets-encryption-key"
  target_key_id = aws_kms_key.secrets.key_id
}
