## Build Boundary Image
```
cd amis/boundary 
packer build -force -var-file="variables.pkrvars.hcl" .
```

## Configure terraform.tfvars
```
deployment_name  = "boundary-ent"
aws_region       = "ap-southeast-1"
controller_count = 1
```

## Configure .envrc file with below values
```
export TF_VAR_user_password=<USER_PASSWORD>
export TF_VAR_boundary_root_username=<BOUNDARY_ROOT_USERNAME>
export TF_VAR_boundary_root_password=<BOUNDARY_ROOT_PASSWORD>
```

## Create Environment
```
terraform apply -auto-approve -target module.boundary-cluster
terraform apply -auto-approve -target module.boundary-workers
terraform apply -auto-approve -target module.boundary-resources
terraform apply -auto-approve -target module.ssh-target
terraform apply -auto-approve -target module.db-target
terraform apply -auto-approve -target module.rdp-target
terraform apply -auto-approve -target module.k8s-cluster
terraform apply -auto-approve -target module.k8s-target
```

## Destroy Environment
```
terraform apply -auto-approve -target module.k8s-target
terraform apply -auto-approve -target module.k8s-cluster
terraform apply -auto-approve -target module.rdp-target
terraform apply -auto-approve -target module.db-target
terraform state rm "module.ssh-target.boundary_storage_bucket.aws"
terraform state rm 'module.boundary-resources.boundary_scope.org'
terraform destroy -auto-approve -target module.ssh-target
terraform destroy -auto-approve -target module.boundary-resources
terraform destroy -auto-approve -target module.boundary-workers
terraform destroy -auto-approve -target module.boundary-cluster
```
