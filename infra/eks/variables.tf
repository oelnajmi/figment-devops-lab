variable "project" {
  type    = string
  default = "figment-devops-lab"
}

variable "env" {
  type    = string
  default = "dev"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "cluster_name" {
  type    = string
  default = "fdl-eks-dev"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

# EKS control plane version; keep this aligned with supported EKS versions
variable "cluster_version" {
  type    = string
  default = "1.30"
}
