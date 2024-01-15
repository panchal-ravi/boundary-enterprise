
# output "vault_credstore_id" {
#   value = boundary_credential_store_vault.cred_store.id
# }


output "resources" {
  value = {
    global_auth_method_id = boundary_auth_method_password.password.id
    org_id                = boundary_scope.org.id
    project_id            = boundary_scope.project.id
    static_credstore_id   = boundary_credential_store_static.static_cred_store.id
    vault_credstore_id    = boundary_credential_store_vault.cred_store.id
    group_admin_id        = boundary_group.admin.id
    group_analyst_id      = boundary_group.analyst.id
  }
}
