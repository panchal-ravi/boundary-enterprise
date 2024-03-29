resource "vault_mount" "db" {
  path = "db"
  type = "database"
}

resource "vault_database_secret_backend_connection" "postgres" {
  backend       = vault_mount.db.path
  name          = "postgres"
  allowed_roles = ["admin", "analyst"]

  postgresql {
    connection_url = "postgres://${var.infra_aws.rds_username}:${var.infra_aws.rds_password}@${var.infra_aws.rds_address}/postgres"
  }
}

resource "vault_database_secret_backend_role" "role_admin" {
  backend             = vault_mount.db.path
  name                = "admin"
  db_name             = vault_database_secret_backend_connection.postgres.name
  creation_statements = ["CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT dba TO \"{{name}}\";"]
  default_ttl         = 300
  max_ttl             = 600
}

resource "vault_database_secret_backend_role" "role_analyst" {
  backend             = vault_mount.db.path
  name                = "analyst"
  db_name             = vault_database_secret_backend_connection.postgres.name
  creation_statements = ["CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT analyst TO \"{{name}}\";"]
  default_ttl         = 300
  max_ttl             = 600
}
