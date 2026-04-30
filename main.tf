terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "github_repo" {
  description = "GitHub repository URL"
  type        = string
  default     = "https://github.com/k-zozulia/ci-cd.git"
}

variable "github_token" {
  description = "GitHub personal access token"
  type        = string
  sensitive   = true
}

module "s3_backend" {
  source      = "./modules/s3-backend"
  bucket_name = "karina-zozulia-tfstate"
  table_name  = "terraform-locks"
}

module "vpc" {
  source             = "./modules/vpc"
  vpc_cidr_block     = "10.0.0.0/16"
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets    = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  availability_zones = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
  vpc_name           = "lesson-8-9-vpc"
}

module "ecr" {
  source       = "./modules/ecr"
  ecr_name     = "lesson-8-9-ecr"
  scan_on_push = true
}

module "eks" {
  source             = "./modules/eks"
  cluster_name       = "lesson-8-9-cluster"
  kubernetes_version = "1.31"
  subnet_ids         = module.vpc.private_subnet_ids
  node_instance_type = "t3.medium"
  node_desired_size  = 2
  node_min_size      = 1
  node_max_size      = 3
}

module "jenkins" {
  source                 = "./modules/jenkins"
  cluster_name           = module.eks.cluster_name
  cluster_endpoint       = module.eks.cluster_endpoint
  cluster_ca_certificate = module.eks.cluster_ca_certificate
  ecr_repository_url     = module.ecr.repository_url
  aws_region             = var.aws_region
  github_repo            = var.github_repo
}

module "argo_cd" {
  source                 = "./modules/argo_cd"
  cluster_name           = module.eks.cluster_name
  cluster_endpoint       = module.eks.cluster_endpoint
  cluster_ca_certificate = module.eks.cluster_ca_certificate
  github_repo            = var.github_repo
  github_token           = var.github_token
}