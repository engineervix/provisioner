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

variable "prevent_terraform_destroy" {
  description = "Prevent Terraform from destroying this resource (stronger protection, requires manual editing of .tf files to remove)"
  type        = bool
  default     = false
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
  description = "Hetzner datacenter location"
  type        = string
  default     = "nbg1"  # Nuremberg, Germany

  validation {
    condition     = contains(["nbg1", "fsn1", "hel1", "ash", "hil"], var.server_location)
    error_message = "Valid values are: nbg1 (Nuremberg), fsn1 (Falkenstein), hel1 (Helsinki), ash (Ashburn, VA, USA), or hil (Hillsboro, OR, USA)."
  }
}

variable "user_name" {
  description = "Username for the non-root user"
  type        = string
  default     = "ubuntu"
}

variable "enable_ssh_ip_restrictions" {
  description = "Whether to restrict SSH access to specific IP addresses"
  type        = bool
  default     = false
}

variable "allowed_ssh_ips" {
  description = "List of IP addresses allowed to connect via SSH (only used if enable_ssh_ip_restrictions = true)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
