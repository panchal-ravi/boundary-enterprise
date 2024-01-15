data "aws_ami" "worker_image" {
  most_recent = true
  owners      = ["self"]
  filter {
    name   = "name"
    values = ["${var.owner}-boundary-enterprise*"]
  }
}

resource "random_id" "worker_auth_storage_kms" {
  byte_length = 32
}

resource "null_resource" "register_ingress_worker" {


  provisioner "file" {
    content     = filebase64("${path.root}/files/boundary/install.sh")
    destination = "/tmp/install_base64.sh"
  }

  provisioner "file" {
    content = templatefile("${path.root}/files/boundary/boundary-worker-ingress.hcl.tpl", {
      controller_lb_dns       = var.infra_aws.controller_internal_dns,
      private_ip              = var.infra_aws.ingress_worker_private_ip,
      public_ip               = var.infra_aws.ingress_worker_public_ip,
      activation_token        = boundary_worker.ingress_worker.controller_generated_activation_token
      worker_auth_storage_kms = random_id.worker_auth_storage_kms.b64_std,
    })
    destination = "/tmp/boundary-worker.hcl"
  }

  provisioner "file" {
    source      = "${path.root}/files/observability/node-exporter.service"
    destination = "/tmp/node-exporter.service"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo base64 -d /tmp/install_base64.sh > /tmp/install.sh",
      "sudo mkdir -p /etc/boundary.d/auth_storage",
      "sudo mkdir -p /etc/boundary.d/session_storage",
      "sudo touch /etc/boundary.d/boundary.env",
      "sudo touch /etc/boundary.d/boundary-recovery-kms.hcl",
      "sudo chown -R boundary:boundary /etc/boundary.d",
      "sudo mv /tmp/install.sh /home/ubuntu/install.sh",
      "sudo chmod +x /home/ubuntu/install.sh",
      "sudo mv /tmp/boundary-worker.hcl /etc/boundary.d/boundary-worker.hcl",
      "sudo /home/ubuntu/install.sh worker",

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

      "sudo systemctl daemon-reload",
      "sudo systemctl start node_exporter",
      "sudo systemctl start boundary-worker",
      "sleep 10",
    ]
  }

  connection {
    host        = var.infra_aws.ingress_worker_public_ip
    user        = "ubuntu"
    agent       = false
    private_key = var.infra_aws.ssh_key //file("${path.root}/generated/ssh_key")
  }

}

resource "boundary_worker" "ingress_worker" {
  description                 = "ingress worker"
  name                        = "ingress-worker"
  scope_id                    = "global"
  worker_generated_auth_token = ""
}
