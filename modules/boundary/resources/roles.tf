# Allows anonymous (un-authenticated) users to list and authenticate against any
# auth method, list the global scope, and read and change password on their account ID
# at the global scope

resource "boundary_role" "global_anon_listing" {
  name     = "global_anon"
  scope_id = boundary_scope.global.id
  grant_strings = [
    "id=*;type=auth-method;actions=list,authenticate",
    "type=scope;actions=list",
    "id={{account.id}};actions=read,change-password"
  ]
  principal_ids = ["u_anon"]
}


# Allows anonymous (un-authenticated) users to list and authenticate against any
# auth method, list the global scope, and read and change password on their account ID
# at the org level scope
resource "boundary_role" "global_admin" {
  scope_id      = boundary_scope.global.id
  name          = "global_admin_role"
  grant_strings = ["id=*;type=*;actions=*"]
  principal_ids = [boundary_user.root.id]
}

resource "boundary_role" "org_admin" {
  scope_id      = boundary_scope.org.id
  name          = "org_admin_role"
  grant_strings = ["id=*;type=*;actions=*"]
  principal_ids = [boundary_user.root.id]
}

resource "boundary_role" "project_admin" {
  scope_id      = boundary_scope.project.id
  name          = "project_admin_role"
  grant_strings = ["id=*;type=*;actions=*"]
  principal_ids = [boundary_user.root.id]
}

resource "boundary_role" "org_anon_listing" {
  scope_id = boundary_scope.org.id
  name     = "org_anon"
  grant_strings = [
    "id=*;type=auth-method;actions=list,authenticate",
    "type=scope;actions=list",
    "id={{account.id}};actions=read,change-password"
  ]
  principal_ids = ["u_anon"]
}
