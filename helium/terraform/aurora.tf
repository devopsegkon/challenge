# Get EKS cluster SG
data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

# DB Subnet Group
resource "aws_db_subnet_group" "aurora" {
  name       = "aurora-subnet-group"
  subnet_ids = module.vpc.private_subnets

  tags = {
    Name = "aurora-subnet-group"
  }
}

# Security Group for Aurora
resource "aws_security_group" "aurora" {
  name_prefix = "aurora-"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [module.eks.cluster_security_group_id, module.eks.node_security_group_id]
  }

  tags = {
    Name = "aurora-sg"
  }
  # Wait for EKS cluster to exist
  depends_on = [module.eks]

}

# Secrets Manager: Store username and password
resource "random_password" "aurora_password" {
  length           = 16
  special          = true
  override_special = "!#*"
}


# (Secrets Manager part)
resource "aws_secretsmanager_secret" "aurora_credentials" {
  name        = "${var.aurora_cluster_name}-credentials"
  description = "Aurora PostgreSQL master credentials"

  # USE SEPARATE KMS KEY
  kms_key_id = aws_kms_key.secrets.arn

  recovery_window_in_days = 7

  tags = { Name = "aurora-credentials" }
}


resource "aws_secretsmanager_secret_version" "aurora_credentials" {
  secret_id = aws_secretsmanager_secret.aurora_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.aurora_password.result
    engine   = "postgres"
    host     = module.aurora_postgresql.cluster_endpoint
    port     = 5432
    dbname   = "mydatabase"
  })
}


module "aurora_postgresql" {
  source  = "terraform-aws-modules/rds-aurora/aws"
  version = "~> 8.0"

  name           = var.aurora_cluster_name
  engine         = "aurora-postgresql"
  engine_mode    = "provisioned"
  engine_version = null
  database_name  = "mydb"

  master_username = "dbadmin"
  master_password = random_password.aurora_password.result

  iam_database_authentication_enabled = true

  vpc_id                 = module.vpc.vpc_id
  subnets                = module.vpc.private_subnets
  create_db_subnet_group = false
  db_subnet_group_name   = aws_db_subnet_group.aurora.name
  vpc_security_group_ids = [aws_security_group.aurora.id]

  serverlessv2_scaling_configuration = {
    min_capacity = 0.5
    max_capacity = 2.0
  }

  instances = {
    writer = { instance_class = "db.serverless" }
    reader = { instance_class = "db.serverless" }
  }

  # USE SEPARATE KMS KEY
  storage_encrypted = true
  kms_key_id        = aws_kms_key.aurora.arn

  backup_retention_period = 7
  skip_final_snapshot     = false
  deletion_protection     = true

  enabled_cloudwatch_logs_exports = ["postgresql"]
  performance_insights_enabled    = true

  apply_immediately = true

  tags = { Environment = "dev" }
}
