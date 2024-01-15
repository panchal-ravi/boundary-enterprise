locals {
  key_name     = "ssh_key"
  rsa_key_name = "rsa_key"
  kms_recovery = templatefile("${path.root}/files/boundary/boundary-recovery-kms.hcl.tpl", {
    recovery_kms = random_id.recovery_kms.b64_std
  })
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "aws_key_pair" "this" {
  key_name   = "${var.deployment_id}-key"
  public_key = tls_private_key.ssh.public_key_openssh
}

resource "local_file" "private_key" {
  content  = tls_private_key.ssh.private_key_openssh
  filename = "${path.root}/generated/${local.key_name}"

  provisioner "local-exec" {
    command = "chmod 400 ${path.root}/generated/${local.key_name}"
  }
}

/*
resource "local_file" "private_rsa_key" {
  content  = tls_private_key.ssh.private_key_pem
  filename = "${path.root}/generated/${local.rsa_key_name}"

  provisioner "local-exec" {
    command = "chmod 400 ${path.root}/generated/${local.rsa_key_name}"
  }
}
*/

data "aws_ami" "an_image" {
  most_recent = true
  owners      = ["self"]
  filter {
    name   = "name"
    values = ["${var.owner}-boundary-enterprise*"]
  }
}

resource "random_id" "root_kms" {
  byte_length = 32
}

resource "random_id" "recovery_kms" {
  byte_length = 32
}

resource "random_id" "worker_auth_kms" {
  byte_length = 32
}
resource "random_id" "bsr_kms" {
  byte_length = 32
}

resource "aws_instance" "controller" {
  count           = var.controller_count
  ami             = data.aws_ami.an_image.id
  instance_type   = var.instance_type
  key_name        = aws_key_pair.this.key_name
  subnet_id       = element(module.vpc.private_subnets, count.index % length(module.vpc.private_subnets))
  security_groups = [module.controller_sg.security_group_id]

  lifecycle {
    ignore_changes = all
  }

  tags = {
    Name  = "${var.deployment_id}-controller"
    owner = var.owner
  }

  provisioner "file" {
    content     = filebase64("${path.root}/files/boundary/install.sh")
    destination = "/tmp/install_base64.sh"
  }

  provisioner "file" {
    content = templatefile("${path.root}/files/boundary/boundary-controller.hcl.tpl", {
      count             = count.index
      private_ip        = self.private_ip,
      controller_lb_dns = aws_lb.controller_internal_lb.dns_name
      root_kms          = random_id.root_kms.b64_std,
      worker_auth_kms   = random_id.worker_auth_kms.b64_std,
      bsr_kms           = random_id.bsr_kms.b64_std,
    })
    destination = "/tmp/boundary-controller.hcl"
  }

  provisioner "file" {
    /*
    content = templatefile("${path.root}/files/boundary/boundary-recovery-kms.hcl.tpl", {
      recovery_kms = random_id.recovery_kms.b64_std
    })
    */
    content     = local.kms_recovery
    destination = "/tmp/boundary-recovery-kms.hcl"
  }

  provisioner "file" {
    content = templatefile("${path.root}/files/boundary/boundary.env.tpl", {
      postgresql_connection_string = "postgresql://${random_string.username.result}:${random_string.password.result}@${aws_db_instance.this.address}:5432/${aws_db_instance.this.db_name}",
      aws_access_key_id            = "",
      aws_secret_access_key        = ""
    })
    destination = "/tmp/boundary.env"
  }

  provisioner "file" {
    source      = "${path.root}/files/boundary/license.hclic"
    destination = "/tmp/license.hclic"
  }

  provisioner "file" {
    content     = tls_locally_signed_cert.controller_signed_cert.cert_pem
    destination = "/tmp/boundary-cert.pem"
  }


  provisioner "file" {
    content     = tls_private_key.controller_private_key.private_key_pem
    destination = "/tmp/boundary-key.pem"
  }

  provisioner "file" {
    content     = tls_private_key.ssh.private_key_openssh
    destination = "/home/ubuntu/ssh_key"
  }

  provisioner "file" {
    source      = "${path.root}/files/observability/node-exporter.service"
    destination = "/tmp/node-exporter.service"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo base64 -d /tmp/install_base64.sh > /tmp/install.sh",
      "sudo mkdir -p /etc/boundary.d/tls",
      "sudo mv /tmp/install.sh /home/ubuntu/install.sh",
      "sudo mv /tmp/boundary-controller.hcl /etc/boundary.d/boundary-controller.hcl",
      "sudo mv /tmp/boundary-recovery-kms.hcl /etc/boundary.d/boundary-recovery-kms.hcl",
      "sudo mv /tmp/boundary.env /etc/boundary.d/boundary.env",
      "sudo mv /tmp/license.hclic /etc/boundary.d/license.hclic",
      "sudo mv /tmp/boundary-key.pem /etc/boundary.d/tls/boundary-key.pem",
      "sudo mv /tmp/boundary-cert.pem /etc/boundary.d/tls/boundary-cert.pem",

      "sudo mv /tmp/node-exporter.service /etc/systemd/system/node_exporter.service",
      "sudo groupadd -f node_exporter",
      "sudo useradd -g node_exporter --no-create-home --shell /bin/false node_exporter",
      "sudo mkdir /etc/node_exporter.d",
      "sudo chown node_exporter:node_exporter /etc/node_exporter.d",
      "sudo wget https://github.com/prometheus/node_exporter/releases/download/v1.5.0/node_exporter-1.5.0.linux-amd64.tar.gz",
      "sudo tar -xvf node_exporter-1.5.0.linux-amd64.tar.gz",
      "sudo mv node_exporter-1.5.0.linux-amd64 node_exporter-files",
      "sudo cp node_exporter-files/node_exporter /usr/local/bin/",
      "sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter",
      "sudo chmod 664 /etc/systemd/system/node_exporter.service",

      "wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -",
      "echo \"deb https://artifacts.elastic.co/packages/8.x/apt stable main\" | sudo tee -a /etc/apt/sources.list.d/elastic-8.x.list",
      "sudo apt-get update && sudo apt-get install filebeat",

      "sudo chmod +x /home/ubuntu/install.sh",
      "sudo chmod 400 /home/ubuntu/ssh_key",
      "sudo /home/ubuntu/install.sh controller",
      "sudo /bin/sh -c \"if [ ${count.index} -eq 0 ]; then POSTGRESQL_CONNECTION_STRING='postgresql://${random_string.username.result}:${random_string.password.result}@${aws_db_instance.this.address}:5432/${aws_db_instance.this.db_name}' /usr/local/bin/boundary database init -skip-host-resources-creation  -skip-auth-method-creation -skip-scopes-creation -skip-target-creation -config /etc/boundary.d/boundary-controller.hcl -format json > /home/ubuntu/db_init.json; fi\"",
      /* "sudo /bin/sh -c \"if [ -s db_init.json ]; then jq -r '.auth_method.password' db_init.json; fi\" > /home/ubuntu/boundary_password", */
      /* "sudo /bin/sh -c \"if [ -s db_init.json ]; then jq -r '.auth_method.auth_method_id' db_init.json; fi\" > /home/ubuntu/global_auth_method_id", */
      "sleep 20",

      "sudo systemctl daemon-reload",
      "sudo systemctl start boundary-controller",
      "sudo systemctl start node_exporter",
      "sudo systemctl enable filebeat",
      "sleep 10",
    ]
  }

  connection {
    bastion_host        = aws_instance.ingress_worker.public_ip
    bastion_user        = "ubuntu"
    agent               = false
    bastion_private_key = tls_private_key.ssh.private_key_openssh

    host        = self.private_ip
    user        = "ubuntu"
    private_key = tls_private_key.ssh.private_key_openssh
  }

  depends_on = [
    aws_db_instance.this
  ]
}

resource "null_resource" "copy" {

  provisioner "local-exec" {
    command = <<-EOT
      ssh -o StrictHostKeyChecking=no -i ${path.root}/generated/${local.key_name} ubuntu@${aws_instance.ingress_worker.public_ip} "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i /home/ubuntu/ssh_key ubuntu@${aws_instance.controller[0].private_ip}:/etc/boundary.d/boundary-recovery-kms.hcl /home/ubuntu/kms_recovery.hcl"
      # scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${path.root}/generated/${local.key_name} ubuntu@${aws_instance.ingress_worker.public_ip}:/home/ubuntu/kms_recovery.hcl ./generated/
      EOT
  }

  connection {
    bastion_host        = aws_instance.ingress_worker.public_ip
    bastion_user        = "ubuntu"
    agent               = false
    bastion_private_key = tls_private_key.ssh.private_key_openssh

    host        = aws_instance.controller[0].private_ip
    user        = "ubuntu"
    private_key = tls_private_key.ssh.private_key_openssh
  }

  depends_on = [
    aws_instance.controller
  ]
}


resource "null_resource" "delete" {

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOD
      # rm ${path.root}/generated/kms_recovery.hcl
      rm ${path.root}/generated/k8s_auth_request_token || true
      rm ${path.root}/generated/k8s_ca.crt || true
      rm ${path.root}/kubeconfig || true
      EOD
  }
  depends_on = [module.vpc]
}
