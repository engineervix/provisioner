variable "enable_delete_protection" {
  description = "Enable Hetzner Cloud API delete protection lock to prevent deletion via API"
  type        = bool
  default     = true
}

variable "enable_rebuild_protection" {
  description = "Enable Hetzner Cloud API rebuild protection to prevent rebuilding via API"
  type        = bool
  default     = true
}

variable "hcloud_token" {
  description = "Hetzner Cloud API Token"
  type        = string
  sensitive   = true
}

variable "ssh_public_key_path" {
  description = "Path to your SSH public key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "server_name" {
  description = "Name for the server"
  type        = string
  default     = "ubuntu-server"
}

variable "server_location" {
  description = "Hetzner location"
  type        = string
  default     = "nbg1" # Nuremberg, Germany

  # Keep in sync with server_type in main.tf: CX types are EU-only
  validation {
    condition     = contains(["nbg1", "fsn1", "hel1"], var.server_location)
    error_message = "cx23 is only available in nbg1 (Nuremberg), fsn1 (Falkenstein) or hel1 (Helsinki)."
  }
}

variable "user_name" {
  description = "Username for the non-root user"
  type        = string
  default     = "ubuntu"
}

variable "allowed_ssh_ips" {
  description = "CIDRs allowed to connect via SSH (default: anywhere)"
  type        = list(string)
  default     = ["0.0.0.0/0", "::/0"]
}
