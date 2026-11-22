terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.63.0"
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
  server_type = "cx23" # x86, 2 vCPU, 4 GB RAM, 40GB SSD
  location    = var.server_location
  ssh_keys    = [hcloud_ssh_key.default.id]

  # Attach at creation so the server is never exposed without it
  firewall_ids = [hcloud_firewall.web_firewall.id]

  # Enable Hetzner Cloud API delete protection
  delete_protection = var.enable_delete_protection

  # Enable Hetzner Cloud API rebuild protection
  rebuild_protection = var.enable_rebuild_protection

  # user_data only runs on first boot, and changing it forces a new server.
  # Edits to cloud-init.yml apply to the next server you create, not this one.
  lifecycle {
    ignore_changes = [user_data]
  }

  # Basic cloud-init configuration
  user_data = templatefile("${path.module}/cloud-init.yml", {
    username       = var.user_name
    ssh_public_key = hcloud_ssh_key.default.public_key
    server_name    = var.server_name
  })

  # Enable backups
  backups = true
}

# Create a basic firewall
resource "hcloud_firewall" "web_firewall" {
  name = "web-firewall"

  # SSH access
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = var.allowed_ssh_ips
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

output "server_ip" {
  value = hcloud_server.ubuntu_server.ipv4_address
}
