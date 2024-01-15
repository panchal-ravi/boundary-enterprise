locals {
  deployment_id = lower("${var.deployment_name}-${random_string.suffix.result}")
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

module "boundary-cluster" {
  source           = "./modules/infra/aws/cluster"
  deployment_id    = local.deployment_id
  owner            = var.owner
  vpc_cidr         = var.aws_vpc_cidr
  public_subnets   = var.aws_public_subnets
  private_subnets  = var.aws_private_subnets
  instance_type    = var.aws_instance_type
  controller_count = var.controller_count
}

module "boundary-workers" {
  source = "./modules/infra/aws/workers"
  providers = {
    boundary = boundary.recovery
  }
  owner         = var.owner
  deployment_id = local.deployment_id
  instance_type = var.aws_instance_type
  infra_aws     = module.boundary-cluster.infra_aws
}

module "boundary-resources" {
  source = "./modules/boundary/resources"
  providers = {
    boundary = boundary.recovery
  }
  vault_ip               = module.boundary-cluster.infra_aws.vault_ip
  user_password          = var.user_password
  boundary_root_username = var.boundary_root_username
  boundary_root_password = var.boundary_root_password
}

module "ssh-target" {
  count              = var.ssh_target ? 1 : 0
  source             = "./modules/boundary/targets/ssh-target"
  deployment_id      = local.deployment_id
  owner              = var.owner
  infra_aws          = module.boundary-cluster.infra_aws
  boundary_resources = module.boundary-resources.resources
}

module "rdp-target" {
  count              = var.rdp_target ? 1 : 0
  source             = "./modules/boundary/targets/rdp-target"
  owner              = var.owner
  deployment_id      = local.deployment_id
  infra_aws          = module.boundary-cluster.infra_aws
  boundary_resources = module.boundary-resources.resources
}

module "db-target" {
  count              = var.db_target ? 1 : 0
  source             = "./modules/boundary/targets/db-target"
  deployment_id      = local.deployment_id
  infra_aws          = module.boundary-cluster.infra_aws
  boundary_resources = module.boundary-resources.resources
}

module "k8s-cluster" {
  count         = var.k8s_target ? 1 : 0
  source        = "./modules/infra/aws/k8s"
  owner         = var.owner
  region        = var.aws_region
  deployment_id = local.deployment_id
  infra_aws     = module.boundary-cluster.infra_aws
}


module "k8s-target" {
  count              = var.k8s_target ? 1 : 0
  source             = "./modules/boundary/targets/k8s-target"
  owner              = var.owner
  region             = var.aws_region
  deployment_id      = local.deployment_id
  eks_cluster_id     = module.k8s-cluster[0].eks_cluster_id
  infra_aws          = module.boundary-cluster.infra_aws
  boundary_resources = module.boundary-resources.resources
}


