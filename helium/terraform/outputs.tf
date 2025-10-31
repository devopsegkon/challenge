output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "aurora_endpoint" {
  value = module.aurora_postgresql.cluster_endpoint
}

output "alb_dns_name" {
  value = module.alb.lb_dns_name
}

output "eks_cluster_id" {
  value = module.eks.cluster_id
}

output "eks_node_sg_id" {
  value = data.aws_security_group.eks_node_sg.id
}

output "aurora_sg_id" {
  value = aws_security_group.aurora.id
}

output "irsa_role_arn" {
  value       = module.eks_pod_iam_role.iam_role_arn
  description = "To use in pod's ServiceAccount annotation"
}

output "cluster_name" {
  value = module.eks.cluster_name
}

# infra/outputs.tf
output "eks_oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}

output "eks_pod_iam_role_arn" {
  value = module.eks_pod_iam_role.iam_role_arn
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "eks_node_security_group_id" {
  value = module.eks.node_security_group_id
}