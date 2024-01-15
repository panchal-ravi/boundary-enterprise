resource "boundary_auth_method_password" "password" {
  scope_id              = boundary_scope.global.id
  description           = "Password authenticate method"
  min_login_name_length = 5
  min_password_length   = 8
}

resource "boundary_account_password" "root" {
  auth_method_id = boundary_auth_method_password.password.id
  login_name     = var.boundary_root_username
  password       = var.boundary_root_password
}

resource "boundary_user" "root" {
  name        = var.boundary_root_username
  description = "root user resource"
  account_ids = [boundary_account_password.root.id]
  scope_id    = boundary_scope.global.id
}

resource "boundary_auth_method_password" "org_auth_pwd" {
  scope_id              = boundary_scope.org.id
  description           = "Password authenticate method"
  min_login_name_length = 5
  min_password_length   = 8
  
}

resource "boundary_account_password" "admin" {
  auth_method_id = boundary_auth_method_password.org_auth_pwd.id
  login_name     = "admin"
  password       = var.user_password
}

resource "boundary_user" "admin" {
  name        = "admin"
  description = "sysadmin user"
  account_ids = [boundary_account_password.admin.id]
  scope_id    = boundary_scope.org.id
}

resource "boundary_group" "admin" {
  name        = "admin"
  description = "Admin Group"
  member_ids  = [boundary_user.admin.id]
  scope_id    = boundary_scope.org.id
}

resource "boundary_account_password" "analyst" {
  auth_method_id = boundary_auth_method_password.org_auth_pwd.id
  login_name     = "analyst"
  password       = var.user_password
}

resource "boundary_user" "analyst" {
  name        = "analyst"
  description = "analyst user"
  account_ids = [boundary_account_password.analyst.id]
  scope_id    = boundary_scope.org.id
}

resource "boundary_group" "analyst" {
  name        = "analyst"
  description = "Analyst Group"
  member_ids  = [boundary_user.analyst.id]
  scope_id    = boundary_scope.org.id
}


resource "boundary_role" "default_org" {
  name           = "default_org"
  scope_id       = boundary_scope.global.id
  grant_scope_id = boundary_scope.org.id
  grant_strings = [
    "id=${boundary_scope.project.id};actions=read",
    "id={{.User.Id}};actions=read",
    "id=*;type=auth-token;actions=list,read:self,delete:self"
  ]
  principal_ids = [boundary_group.admin.id, boundary_group.analyst.id]
}

resource "boundary_role" "default_project" {
  name           = "default_project"
  scope_id       = boundary_scope.org.id
  grant_scope_id = boundary_scope.project.id
  grant_strings = [
    "id=*;type=session;actions=list,no-op",
    "id=*;type=session;actions=read:self,cancel:self",
  ]
  principal_ids = [boundary_group.admin.id, boundary_group.analyst.id]
}