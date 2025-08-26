data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  # Pick two AZs for simplicity
  azs = slice(data.aws_availability_zones.available.names, 0, 2)

  # Derive 4 subnets (2 public + 2 private) from the /16
  public_subnets  = [cidrsubnet(var.vpc_cidr, 8, 0), cidrsubnet(var.vpc_cidr, 8, 1)]
  private_subnets = [cidrsubnet(var.vpc_cidr, 8, 10), cidrsubnet(var.vpc_cidr, 8, 11)]

  common_tags = {
    Project = var.project
    Env     = var.env
  }
}

# VPC for the cluster
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.project}-${var.env}-vpc"
  cidr = var.vpc_cidr

  azs             = local.azs
  public_subnets  = local.public_subnets
  private_subnets = local.private_subnets

  enable_nat_gateway   = false
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  # ensure public subnets auto-assign public IPs	
  map_public_ip_on_launch = true

  # Tag subnets for load balancers and cluster discovery
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  tags = local.common_tags
}

# EKS cluster with one managed node group
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name                             = var.cluster_name
  cluster_version                          = var.cluster_version
  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true

  # Control plane logs (handy for debugging)
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets

  eks_managed_node_groups = {
    default = {
      ami_type       = "AL2_x86_64"
      instance_types = ["t3.micro", "t2.micro"]
      desired_size   = 1
      min_size       = 1
      max_size       = 1
      capacity_type  = "ON_DEMAND"
    }
  }

  tags = local.common_tags
}
