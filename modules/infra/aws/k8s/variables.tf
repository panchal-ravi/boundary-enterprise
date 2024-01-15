variable "deployment_id" {
  type = string
}
variable "owner" {
  type = string
}
variable "region" {
  type = string
}
variable "infra_aws" {
  type = object({
    vpc_cidr_block                   = string
    vpc_id                           = string
    public_subnets                   = list(string)
    private_subnets                  = list(string)
    aws_keypair_key_name             = string
    ssh_key                          = string
  })
}