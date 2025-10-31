variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.0.0.0/16"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "my-eks-cluster"
}

variable "aurora_cluster_name" {
  description = "Aurora cluster name"
  type        = string
  default     = "my-aurora-cluster"
}

variable "db_username" {
  description = "Aurora master username"
  type        = string
  default     = "dbadmin"
}

variable "instance_type" {
  description = "EKS node instance type"
  type        = string
  default     = "t3.small"
}

variable "cluster_endpoint_public_access" {
  description = "Enable public access to EKS API"
  type        = bool
  default     = false  # Default: private only
}
