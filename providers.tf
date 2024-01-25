terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.20.0"
    }
    boundary = {
      source  = "hashicorp/boundary"
      version = "~> 1.1.9"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "3.8.2"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "~> 2.23.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}


provider "boundary" {
  alias            = "recovery"
  addr             = "https://${module.boundary-cluster.infra_aws.boundary_cluster_url}"
  recovery_kms_hcl = module.boundary-cluster.infra_aws.kms_recovery //trimspace(file("${path.root}/generated/kms_recovery.hcl"))
  tls_insecure     = true
}


provider "boundary" {
  addr                   = "https://${module.boundary-cluster.infra_aws.boundary_cluster_url}"
  auth_method_id         = module.boundary-resources.resources.global_auth_method_id
  auth_method_login_name = var.boundary_root_username
  auth_method_password   = var.boundary_root_password
  tls_insecure           = true
}

provider "vault" {
  address = "https://${module.boundary-cluster.infra_aws.boundary_cluster_url}:8200"
  token   = module.boundary-cluster.infra_aws.vault_token
  skip_tls_verify = true
}

# The Kubernetes provider is included here so the EKS module can complete successfully. Otherwise, it throws an error when creating `kubernetes_config_map.aws_auth`.
# Retrieve EKS cluster configuration
data "aws_eks_cluster" "cluster" {
  name = module.k8s-cluster.eks_cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.k8s-cluster.eks_cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  token                  = data.aws_eks_cluster_auth.cluster.token
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
}
