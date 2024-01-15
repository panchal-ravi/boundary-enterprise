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

resource "aws_instance" "ingress_worker" {
  ami                  = data.aws_ami.an_image.id
  instance_type        = var.instance_type
  key_name             = aws_key_pair.this.key_name
  subnet_id            = element(module.vpc.public_subnets, 1)
  security_groups      = [module.ingress_worker_sg.security_group_id]
  iam_instance_profile = aws_iam_instance_profile.worker_instance_profile.name

  lifecycle {
    ignore_changes = all
  }

  tags = {
    Name  = "${var.deployment_id}-worker-ingress"
    owner = var.owner
  }

  provisioner "file" {
    content     = tls_private_key.ssh.private_key_openssh //file("${path.root}/generated/ssh_key")
    destination = "/home/ubuntu/ssh_key"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod 400 /home/ubuntu/ssh_key",
    ]
  }

  connection {
    host        = self.public_ip
    user        = "ubuntu"
    agent       = false
    private_key = tls_private_key.ssh.private_key_openssh //file("${path.root}/generated/ssh_key")
  }

}
