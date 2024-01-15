variable "deployment_id" {
  type = string
}
variable "infra_aws" {
  type = object({
    vpc_cidr_block                   = string
    vpc_id                           = string
    public_subnets                   = list(string)
    private_subnets                  = list(string)
    aws_keypair_key_name             = string
    controller_internal_dns          = string
    ingress_worker_public_ip         = string
    vault_ip                         = string
    vault_security_group_id          = string
    boundary_cluster_url             = string
    session_storage_role_arn         = string
    ssh_key                          = string
    worker_ingress_security_group_id = string
    # bastion_security_group_id        = string
    # worker_instance_profile          = string
    # worker_egress_security_group_id  = string
    rds_address                      = string
    rds_username                     = string
    rds_password                     = string
  })
}

variable "boundary_resources" {
  type = object({
    org_id              = string
    project_id          = string
    static_credstore_id = string
    vault_credstore_id  = string
    group_admin_id      = string
    group_analyst_id    = string
  })
}