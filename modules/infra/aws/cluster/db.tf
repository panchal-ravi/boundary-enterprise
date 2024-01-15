resource "aws_db_subnet_group" "this" {
  name       = "${var.deployment_id}-subnet-group"
  subnet_ids = module.vpc.private_subnets

  tags = {
    Name = "boundary-enterprise-database"
  }
}

resource "random_string" "username" {
  length  = 8
  lower   = true
  special = false
  numeric = false
}

resource "random_string" "password" {
  length  = 12
  lower   = true
  upper   = true
  numeric = true
  special = false
}

resource "aws_db_instance" "this" {
  identifier             = "${var.deployment_id}-db"
  instance_class         = "db.t3.micro"
  allocated_storage      = 10
  engine                 = "postgres"
  db_name                = "boundary"
  engine_version         = "13.7"
  username               = random_string.username.result   //var.controller_db_username
  password               = random_string.password.result //var.controller_db_password
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [module.rds_sg.security_group_id]
  parameter_group_name   = aws_db_parameter_group.this.name
  publicly_accessible    = false
  skip_final_snapshot    = true
}

resource "aws_db_parameter_group" "this" {
  name   = "${var.deployment_id}-grp"
  family = "postgres13"

  parameter {
    name  = "log_connections"
    value = "1"
  }
}
/*
resource "null_resource" "create-db" {
  provisioner "remote-exec" {
    inline = [
      #"sudo apt-get install -y postgresql-client", 
      # "sleep 10",
      "PGPASSWORD=${random_password.password.result} psql -h ${aws_db_instance.this.address} -U ${random_string.username.result} postgres -c 'CREATE ROLE ANALYST NOINHERIT;'",
      "PGPASSWORD=${random_password.password.result} psql -h ${aws_db_instance.this.address} -U ${random_string.username.result} postgres -c 'GRANT CONNECT ON DATABASE POSTGRES TO ANALYST;'",
      "PGPASSWORD=${random_password.password.result} psql -h ${aws_db_instance.this.address} -U ${random_string.username.result} postgres -c 'GRANT USAGE ON SCHEMA PUBLIC TO ANALYST;'",
      "PGPASSWORD=${random_password.password.result} psql -h ${aws_db_instance.this.address} -U ${random_string.username.result} postgres -c 'GRANT SELECT ON ALL TABLES IN SCHEMA PUBLIC TO ANALYST;'",
      "PGPASSWORD=${random_password.password.result} psql -h ${aws_db_instance.this.address} -U ${random_string.username.result} postgres -c 'GRANT USAGE ON ALL SEQUENCES IN SCHEMA PUBLIC TO ANALYST;'",
      "PGPASSWORD=${random_password.password.result} psql -h ${aws_db_instance.this.address} -U ${random_string.username.result} postgres -c 'GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA PUBLIC TO ANALYST;'",
      "PGPASSWORD=${random_password.password.result} psql -h ${aws_db_instance.this.address} -U ${random_string.username.result} postgres -c 'CREATE ROLE DBA NOINHERIT;'",
      "PGPASSWORD=${random_password.password.result} psql -h ${aws_db_instance.this.address} -U ${random_string.username.result} postgres -c 'GRANT CONNECT ON DATABASE POSTGRES TO DBA;'",
      "PGPASSWORD=${random_password.password.result} psql -h ${aws_db_instance.this.address} -U ${random_string.username.result} postgres -c 'GRANT ALL PRIVILEGES ON DATABASE POSTGRES TO DBA;'",
      "PGPASSWORD=${random_password.password.result} psql -h ${aws_db_instance.this.address} -U ${random_string.username.result} postgres -c 'GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA PUBLIC TO DBA;'",
      "PGPASSWORD=${random_password.password.result} psql -h ${aws_db_instance.this.address} -U ${random_string.username.result} postgres -c \"CREATE TABLE COUNTRY(CODE VARCHAR, NAME VARCHAR);\"",
      "PGPASSWORD=${random_password.password.result} psql -h ${aws_db_instance.this.address} -U ${random_string.username.result} postgres -c \"INSERT INTO COUNTRY VALUES('SG', 'SINGAPORE');\"",
      "sleep 5",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "PGPASSWORD=${random_password.password.result} psql -h ${aws_db_instance.this.address} -U ${random_string.username.result} postgres -c 'GRANT SELECT ON ALL TABLES IN SCHEMA PUBLIC TO ANALYST;'",
      "PGPASSWORD=${random_password.password.result} psql -h ${aws_db_instance.this.address} -U ${random_string.username.result} postgres -c 'GRANT ALL PRIVILEGES ON DATABASE POSTGRES TO DBA;'",
      "PGPASSWORD=${random_password.password.result} psql -h ${aws_db_instance.this.address} -U ${random_string.username.result} postgres -c 'GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA PUBLIC TO DBA;'",
    ]
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    host        = aws_instance.ingress_worker.public_ip
    private_key = tls_private_key.ssh.private_key_openssh
  }

  depends_on = [aws_db_instance.this]
}
*/

