terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.50.1"
    }
  }
  required_version = ">= 1.11.0"
}

# Configure the Hetzner Cloud Provider
provider "hcloud" {
  token = var.hcloud_token
}

# Create SSH key resource from your public key
resource "hcloud_ssh_key" "default" {
  name       = "default-ssh-key"
  public_key = file(var.ssh_public_key_path)
}

# Create a new server
resource "hcloud_server" "ubuntu_server" {
  name        = var.server_name
  image       = "docker-ce"
  server_type = "cax21" # Arm64, 4 vCPU, 8 GB RAM
  location    = var.server_location
  ssh_keys    = [hcloud_ssh_key.default.id]

  # Enable Hetzner Cloud API delete protection
  delete_protection = var.enable_delete_protection

  # Enable Hetzner Cloud API rebuild protection
  rebuild_protection = var.enable_rebuild_protection

  # Prevent accidental deletion through Terraform itself
  lifecycle {
    prevent_destroy = false
  }

  # Basic cloud-init configuration
  user_data = templatefile("${path.module}/cloud-init.yml", {
    username       = var.user_name
    ssh_public_key = file(var.ssh_public_key_path)
    server_name    = var.server_name
  })

  # Enable backups
  backups = true

  # Wait for the server to be available via SSH
  connection {
    type        = "ssh"
    user        = "root"
    host        = self.ipv4_address
    agent       = true
    timeout     = "2m"
  }

  # Basic provisioner to test SSH connection
  provisioner "remote-exec" {
    inline = ["echo 'SSH connection established!'"]
  }
}

# Create a basic firewall
resource "hcloud_firewall" "web_firewall" {
  name = "web-firewall"

  # SSH access - conditionally restrict by IP based on user preference
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = var.enable_ssh_ip_restrictions ? var.allowed_ssh_ips : ["0.0.0.0/0", "::/0"]
  }

  # HTTP access
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "80"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  # HTTPS access
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "443"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  # ICMP (ping)
  rule {
    direction  = "in"
    protocol   = "icmp"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
}

# Apply firewall to server
resource "hcloud_firewall_attachment" "web_firewall" {
  firewall_id = hcloud_firewall.web_firewall.id
  server_ids  = [hcloud_server.ubuntu_server.id]
}

# Output server IP and other details
output "server_ip" {
  value = hcloud_server.ubuntu_server.ipv4_address
}

output "server_status" {
  value = hcloud_server.ubuntu_server.status
}
