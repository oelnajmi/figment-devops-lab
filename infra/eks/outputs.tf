output "cluster_name" { value = module.eks.cluster_name }
output "cluster_region" { value = var.region }
output "cluster_endpoint" { value = module.eks.cluster_endpoint }
output "nodegroup_arn" { value = try(module.eks.eks_managed_node_groups["default"].node_group_arn, null) }
