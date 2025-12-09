# README.md

# Lab Infrastructure

This repository contains the Terraform configurations and templates used to manage the infrastructure for my homelab, all deployed on Proxmox. It is designed to provide a structured, modular, and reproducible setup for both core infrastructure and cluster deployments.

## Repository Structure

```
lab-infrastructure/
├── core/
├── cluster/
├── README.md
└── ...
```

### Core Folder

The `core/` folder contains the primary infrastructure deployment and supporting services:

* **Core Infrastructure Deployment**: Terraform configurations for provisioning the foundational lab infrastructure on Proxmox.
* **External DNS Configuration**: Manages external DNS records for the lab domain.
* **Bind9 DNS Setup**: Terraform-managed Bind9 configuration for internal DNS resolution.
* **Ubuntu Cloud-Init Template VM**: Preconfigured Ubuntu VM templates using cloud-init for consistent lab deployments on Proxmox.

### Cluster Folder

The `cluster/` folder contains the configurations for deploying and managing a Talos Linux-based cluster:

* **Talos Linux Deployment**: Terraform configurations to provision a Talos Linux cluster on Proxmox.
* **Cluster Configuration**: Manages control plane and worker node settings.
* **Local DNS for Cluster**: Integrates the cluster with local DNS using Bind9 for internal resolution and service discovery.
* **External DNS for Public Services**: Configures DNS records for any public-facing services hosted within the cluster.
* **Flux Installation and Configuration**: Sets up Flux for GitOps-based management of applications and cluster resources.

## Getting Started

To use these configurations:

1. Ensure Terraform is installed (version ≥ 1.6 recommended).
2. Ensure you have access to your Proxmox environment and the necessary credentials.
3. Configure your Terraform backend and provider settings as required.

### Deploy Core Infrastructure

```bash
cd core
terraform init
terraform plan
terraform apply
```

### Deploy Cluster

```bash
cd cluster
terraform init
terraform plan
terraform apply
```

## Notes

* All infrastructure is deployed on Proxmox VMs.
* This repository is designed for personal lab use.
* All configurations are modular to allow easy extension for additional services or environments.
* Ensure you review and update any sensitive information (such as DNS credentials) before deployment.

## License

[MIT License](LICENSE)
