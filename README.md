# Hetzner Server Provisioning Automation

This repository contains Terraform configurations to automate the provisioning of a Hetzner Cloud server with Docker CE pre-installed.

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Prerequisites](#prerequisites)
- [Setup](#setup)
- [Docker CE Pre-installed](#docker-ce-pre-installed)
- [Server Protection](#server-protection)
- [Next Steps](#next-steps)
- [Verifying Cloud-Init Installation](#verifying-cloud-init-installation)
- [Destroying Resources](#destroying-resources)
- [Important Notes](#important-notes)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) (v1.11.0 or newer)
- A Hetzner Cloud account
- A Hetzner Cloud API token (with read/write permissions)
- SSH key pair

## Setup

1. **Clone this repository**

   ```bash
   git clone https://github.com/engineervix/provisioner.git
   cd provisioner
   ```

2. **Create your terraform.tfvars file**

   Copy the example file and edit it with your values:

   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your text editor
   ```

   Make sure to:
   - Add your Hetzner Cloud API token
   - Specify the correct path to your Public SSH key
   - Set your preferred server name and location

   **Security Note**: By default, SSH access is not restricted by IP address since the assumption is that most users have dynamic IPs. The configuration relies on:
   - SSH key-based authentication (no password access)
   - Fail2ban for protection against brute force attempts
   - UFW firewall as a backup security measure

3. **Set up SSH Agent**

   This configuration uses SSH agent for authentication during provisioning, which allows the use of password-protected SSH keys:

   ```bash
   # Start the SSH agent if not running
   eval "$(ssh-agent -s)"
   
   # Add your private key to the agent (you'll be prompted for the password once)
   ssh-add ~/.ssh/id_rsa
   
   # Verify your key was added
   ssh-add -l
   ```

4. **Initialize Terraform**

   ```bash
   terraform init
   ```

5. **Review the execution plan**

   ```bash
   terraform plan
   ```

   This will show you what resources will be created without making any changes.

6. **Apply the configuration**

   ```bash
   terraform apply
   ```

   Type 'yes' when prompted to create the resources.

7. **Connect to your new server**

   After the provisioning is complete, Terraform will output the IP address of your new server:

   ```bash
   ssh -i ~/.ssh/id_rsa username@<server_ip>
   ```

> [!NOTE]  
> You might be prompted to reboot after initial login.

## Docker CE Pre-installed

This configuration uses Hetzner's [Docker CE](https://docs.hetzner.com/cloud/apps/list/docker-ce/) app image which comes with:
- Ubuntu 24.04 as the base OS
- Docker pre-installed and configured
- Docker Compose plugin pre-installed

You can start using Docker commands immediately after server provisioning.

## Server Protection

This configuration offers three levels of protection for your server:

1. **Hetzner Cloud API Delete Protection** (`delete_protection = true`):
   - Prevents deletion via the Hetzner Cloud API
   - Can be disabled through the Hetzner Cloud Console or API
   - *Note*: This does not prevent deletion by Terraform itself, as Terraform will automatically lift this lock

2. **Hetzner Cloud API Rebuild Protection** (`rebuild_protection = true`):
   - Prevents rebuilding the server via the Hetzner Cloud API
   - Can be disabled through the Hetzner Cloud Console or API

3. **Terraform Destroy Prevention** (`prevent_terraform_destroy = false`, disabled by default):
   - When enabled, this prevents `terraform destroy` from deleting the resource
   - Strongest protection level - requires manual editing of the .tf files to remove
   - Disabled by default to prevent lockout scenarios

You can configure these protection levels in the `terraform.tfvars` file.
- Initial security hardening
- Installation of essential packages
- Configuration of unattended upgrades

## Next Steps

After provisioning, you may want to:

1. Run your Ansible playbooks for further configuration
2. Deploy Docker containers for your applications
3. Configure a reverse proxy such as Traefik, Caddy, NGiИX, etc.

## Verifying Cloud-Init Installation

To verify that everything was installed properly by cloud-init:

1. **Check cloud-init status**
   ```bash
   cloud-init status
   ```

2. **View the main cloud-init log file**
   ```bash
   sudo cat /var/log/cloud-init.log
   ```

3. **Check command outputs and errors**
   ```bash
   sudo cat /var/log/cloud-init-output.log
   ```

4. **Get a detailed analysis of the cloud-init run**
   ```bash
   sudo cloud-init analyze show
   ```

5. **Query specific cloud-init data**
   ```bash
   sudo cloud-init query -a
   ```

If you encounter issues with oh-my-zsh, vim, or any other configuration, these logs will help identify what went wrong.

## Destroying Resources

If you need to tear down the infrastructure:

```bash
terraform destroy
```

> [!NOTE]  
> By default, this wont work unless you manually "disable protection" in your Hetzner dashboard. This is [a protective measure I deliberately added](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs#delete-protection) to prevent accidental deletion.

Type 'yes' when prompted to destroy the resources.

## Important Notes

- The server will be accessible via SSH immediately after provisioning
- The root password authentication is disabled by default
- Only the non-root user specified in the variables can log in via SSH with the specified key
- Make sure to keep your terraform.tfvars file secure as it contains sensitive information
- The user is automatically added to the `docker` group and can run docker commands without sudo
- This configuration uses SSH agent for provisioning, allowing the use of password-protected SSH keys
