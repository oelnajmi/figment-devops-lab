terraform {
  backend "s3" {
    bucket         = "figment-devops-lab-tfstate-dev-1756129966"
    key            = "infra/eks/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "figment-devops-lab-tf-locks-dev"
    encrypt        = true
  }
}
