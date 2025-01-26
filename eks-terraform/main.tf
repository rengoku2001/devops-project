# main.tf

provider "aws" {
  region = var.aws_region
}

terraform {
  backend "s3" {
    bucket         = "myapple123"  # Replace with your S3 bucket name
    key            = "eks/terraform.tfstate"       # State file path
    region         = "ap-south-1"  # Replace with a fixed region value
    encrypt        = true
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "4.0.0"

  name                 = "eks-vpc"
  cidr                 = "10.0.0.0/16"
  azs                  = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  private_subnets      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets       = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  public_subnet_tags   = { "kubernetes.io/role/elb" = "1" }
  private_subnet_tags  = { "kubernetes.io/role/internal-elb" = "1" }
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "19.0.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.27"
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnets

  eks_managed_node_groups = {
    eks_nodes = {
      desired_size = 2
      max_size     = 3
      min_size     = 1
      instance_types = ["t2.micro"]
      key_name       = var.key_name
    }
  }
}

# variables.tf

variable "aws_region" {
  description = "The AWS region to deploy EKS in"
  default     = "ap-south-1"
}

variable "cluster_name" {
  description = "EKS Cluster name"
  default     = "my-eks-cluster"
}

variable "key_name" {
  description = "Name of the SSH key pair"
  default     = "mumbai"  # Replace with your EC2 key pair
}

# outputs.tf

output "eks_cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_id
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_version" {
  description = "EKS Kubernetes version"
  value       = module.eks.cluster_version
}

output "eks_node_group_role_arn" {
  description = "ARN of the worker node IAM role"
  value       = module.eks.eks_managed_node_groups["eks_nodes"].iam_role_arn
}
