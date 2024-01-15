
resource "null_resource" "create-db" {
  provisioner "remote-exec" {
    inline = [
      #"sudo apt-get install -y postgresql-client", 
      # "sleep 10",
      "PGPASSWORD=${var.infra_aws.rds_password} psql -h ${var.infra_aws.rds_address} -U ${var.infra_aws.rds_username} postgres -c 'CREATE ROLE ANALYST NOINHERIT;'",
      "PGPASSWORD=${var.infra_aws.rds_password} psql -h ${var.infra_aws.rds_address} -U ${var.infra_aws.rds_username} postgres -c 'GRANT CONNECT ON DATABASE POSTGRES TO ANALYST;'",
      "PGPASSWORD=${var.infra_aws.rds_password} psql -h ${var.infra_aws.rds_address} -U ${var.infra_aws.rds_username} postgres -c 'GRANT USAGE ON SCHEMA PUBLIC TO ANALYST;'",
      "PGPASSWORD=${var.infra_aws.rds_password} psql -h ${var.infra_aws.rds_address} -U ${var.infra_aws.rds_username} postgres -c 'GRANT SELECT ON ALL TABLES IN SCHEMA PUBLIC TO ANALYST;'",
      "PGPASSWORD=${var.infra_aws.rds_password} psql -h ${var.infra_aws.rds_address} -U ${var.infra_aws.rds_username} postgres -c 'GRANT USAGE ON ALL SEQUENCES IN SCHEMA PUBLIC TO ANALYST;'",
      "PGPASSWORD=${var.infra_aws.rds_password} psql -h ${var.infra_aws.rds_address} -U ${var.infra_aws.rds_username} postgres -c 'GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA PUBLIC TO ANALYST;'",
      "PGPASSWORD=${var.infra_aws.rds_password} psql -h ${var.infra_aws.rds_address} -U ${var.infra_aws.rds_username} postgres -c 'CREATE ROLE DBA NOINHERIT;'",
      "PGPASSWORD=${var.infra_aws.rds_password} psql -h ${var.infra_aws.rds_address} -U ${var.infra_aws.rds_username} postgres -c 'GRANT CONNECT ON DATABASE POSTGRES TO DBA;'",
      "PGPASSWORD=${var.infra_aws.rds_password} psql -h ${var.infra_aws.rds_address} -U ${var.infra_aws.rds_username} postgres -c 'GRANT ALL PRIVILEGES ON DATABASE POSTGRES TO DBA;'",
      "PGPASSWORD=${var.infra_aws.rds_password} psql -h ${var.infra_aws.rds_address} -U ${var.infra_aws.rds_username} postgres -c 'GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA PUBLIC TO DBA;'",
      "PGPASSWORD=${var.infra_aws.rds_password} psql -h ${var.infra_aws.rds_address} -U ${var.infra_aws.rds_username} postgres -c \"CREATE TABLE COUNTRY(CODE VARCHAR, NAME VARCHAR);\"",
      "PGPASSWORD=${var.infra_aws.rds_password} psql -h ${var.infra_aws.rds_address} -U ${var.infra_aws.rds_username} postgres -c \"INSERT INTO COUNTRY VALUES('SG', 'SINGAPORE');\"",
      "sleep 5",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "PGPASSWORD=${var.infra_aws.rds_password} psql -h ${var.infra_aws.rds_address} -U ${var.infra_aws.rds_username} postgres -c 'GRANT SELECT ON ALL TABLES IN SCHEMA PUBLIC TO ANALYST;'",
      "PGPASSWORD=${var.infra_aws.rds_password} psql -h ${var.infra_aws.rds_address} -U ${var.infra_aws.rds_username} postgres -c 'GRANT ALL PRIVILEGES ON DATABASE POSTGRES TO DBA;'",
      "PGPASSWORD=${var.infra_aws.rds_password} psql -h ${var.infra_aws.rds_address} -U ${var.infra_aws.rds_username} postgres -c 'GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA PUBLIC TO DBA;'",
    ]
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    host        = var.infra_aws.ingress_worker_public_ip
    private_key = var.infra_aws.ssh_key
  }

}