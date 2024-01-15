module "eks" {
  source                          = "terraform-aws-modules/eks/aws"
  version                         = "18.26.3"
  cluster_name                    = var.deployment_id
  cluster_version                 = "1.22"
  vpc_id                          = var.infra_aws.vpc_id
  subnet_ids                      = [var.infra_aws.private_subnets[0], var.infra_aws.private_subnets[1]]
  cluster_endpoint_private_access = true
  cluster_service_ipv4_cidr       = "172.20.0.0/18"

  eks_managed_node_group_defaults = {
  }
  cluster_security_group_additional_rules = {
    ops_private_access_egress = {
      description = "Ops Private Egress"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "egress"
      cidr_blocks = [var.infra_aws.vpc_cidr_block]
    }
    ops_private_access_ingress = {
      description = "Ops Private Ingress"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      cidr_blocks = [var.infra_aws.vpc_cidr_block]
    }
  }
  eks_managed_node_groups = {
    default = {
      min_size               = 1
      max_size               = 3
      desired_size           = 2
      instance_types         = ["t3.medium"]
      key_name               = var.infra_aws.aws_keypair_key_name
      vpc_security_group_ids = [module.private-ssh.security_group_id]
    }
  }

  tags = {
    owner = var.owner
  }
}

resource "null_resource" "kubeconfig" {
  provisioner "local-exec" {
    command = "aws eks --region ${var.region} update-kubeconfig --name ${var.deployment_id} --kubeconfig ${path.root}/kubeconfig"
  }

  depends_on = [
    module.eks
  ]
}
