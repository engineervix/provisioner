# Hetzner Server Provisioning Automation

This repository contains Terraform configurations to automate the provisioning of a Hetzner Cloud server with Docker CE pre-installed.

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Prerequisites](#prerequisites)
- [Setup](#setup)
- [Docker CE Pre-installed](#docker-ce-pre-installed)
- [Server Protection](#server-protection)
- [Dotfiles](#dotfiles)
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
   cp terraform-tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your text editor
   ```

   Make sure to:
   - Add your Hetzner Cloud API token
   - Specify the correct path to your Public SSH key
   - Set your preferred server name and location

   **Security Note**: By default, SSH access is not restricted by IP address since the assumption is that most users have dynamic IPs. The configuration relies on:
   - SSH key-based authentication (no password access)
   - Fail2ban for protection against brute force attempts
   - The Hetzner firewall (only 22, 80, 443 and ping are open). It filters traffic before it reaches the server, so it also covers ports published by Docker.
   - UFW on the server, with the same rules. It protects SSH and anything else running directly on the server if the Hetzner firewall is ever detached. Docker-published ports bypass UFW, so it does not protect containers.

   To open another port, add a rule to `hcloud_firewall` in `main.tf`, and to UFW in `cloud-init.yml` if a process on the server (not a container) listens on it. For containers that only need local access (a database, an admin UI), publish them on localhost, for example `127.0.0.1:5432:5432`, or don't publish them at all and let the reverse proxy reach them over the Compose network.

   After any firewall or Compose change, check what the internet can reach by scanning from outside, for example from your laptop: `nmap -Pn -p 22,80,443,5432 <server_ip>`.

3. **Initialize Terraform**

   ```bash
   terraform init
   ```

4. **Review the execution plan**

   ```bash
   terraform plan
   ```

   This will show you what resources will be created without making any changes.

5. **Apply the configuration**

   ```bash
   terraform apply
   ```

   Type 'yes' when prompted to create the resources.

6. **Connect to your new server**

   Terraform outputs the IP address of your new server. Terraform returns as soon as the server exists, but cloud-init keeps working for a few minutes, so wait for it to finish:

   ```bash
   ssh -i ~/.ssh/id_rsa username@<server_ip> cloud-init status --wait
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

This configuration offers two levels of protection for your server:

1. **Hetzner Cloud API Delete Protection** (`delete_protection = true`):
   - Prevents deletion via the Hetzner Cloud API
   - Can be disabled through the Hetzner Cloud Console or API
   - *Note*: This does not prevent deletion by Terraform itself, as Terraform will automatically lift this lock

2. **Hetzner Cloud API Rebuild Protection** (`rebuild_protection = true`):
   - Prevents rebuilding the server via the Hetzner Cloud API
   - Can be disabled through the Hetzner Cloud Console or API

You can configure these protection levels in the `terraform.tfvars` file.

## Dotfiles

The shell and editor config for the server user lives in [`dotfiles/`](dotfiles/) (`zshrc`, `vimrc`, `starship.toml`). On first boot, cloud-init clones this repository into `~/.provisioner` and runs `dotfiles/install.sh`. That script links the files into place and fetches the zsh and vim plugins.

> [!IMPORTANT]
> cloud-init clones the `main` branch, so dotfile changes only reach new servers after they are merged.

To update the dotfiles on an existing server:

```bash
git -C ~/.provisioner pull
```

The files are symlinks, so a pull is enough. Run `~/.provisioner/dotfiles/install.sh` again only if the plugin list changed.

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

If you encounter issues with zsh, vim, or any other configuration, these logs will help identify what went wrong. cloud-init stops at the first failing command, and `cloud-init-output.log` shows each command as it runs.

## Destroying Resources

If you need to tear down the infrastructure:

```bash
terraform destroy
```

> [!NOTE]  
> By default, this wont work unless you manually "disable protection" in your Hetzner dashboard. This is [a protective measure I deliberately added](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs#delete-protection) to prevent accidental deletion.

Type 'yes' when prompted to destroy the resources.

## Important Notes

- SSH works once cloud-init has finished (see step 6 of [Setup](#setup)), not right after `terraform apply`
- The root password authentication is disabled by default
- Only the non-root user specified in the variables can log in via SSH with the specified key
- Make sure to keep your terraform.tfvars file secure as it contains sensitive information
- The user is automatically added to the `docker` group and can run docker commands without sudo
