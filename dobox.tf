terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "2.3.0"
    }
  }
}

variable "pvt_key" {}

data "digitalocean_ssh_key" "edge1-commie-cafe" {
  name = "osp_edge"
}

resource "digitalocean_domain" "edge1-commie-cafe" {
  name       = "edge1.commie.cafe"
  ip_address = digitalocean_droplet.edge1-commie-cafe.ipv4_address
}

resource "digitalocean_droplet" "edge1-commie-cafe" {
  image = "ubuntu-18-04-x64"
  name = "edge1.commie.cafe"
  region = "nyc1"
  size = "s-1vcpu-1gb"
  private_networking = true
  ssh_keys = [ data.digitalocean_ssh_key.edge1-commie-cafe.id ]

  connection {
    host = self.ipv4_address
    user = "root"
    type = "ssh"
    private_key = file(var.pvt_key)
    timeout = "2m"
  }
  provisioner "remote-exec" {
    inline = [
      "export PATH=$PATH:/usr/bin",
      "git clone https://github.com/cagyirey/osp-edge.git",
      "cd osp-edge",
      "chmod +x setup.sh",
      "sudo bash setup.sh <<< '70.64.32.228'"
    ]
  }
}
