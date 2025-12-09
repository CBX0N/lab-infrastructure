terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "3.0.2-rc06"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.10.0-beta.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "3.0.2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.38.0"
    }
    dns = {
      source  = "hashicorp/dns"
      version = "3.2.3"
    }
  }
  backend "s3" {
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    use_path_style              = true
    region                      = "auto"
  }
}

provider "proxmox" {
  pm_api_url          = "https://${var.proxmox.host}:8006/api2/json"
  pm_tls_insecure     = true
  pm_api_token_id     = var.proxmox.token_id
  pm_api_token_secret = var.proxmox.token_secret
}

provider "cloudflare" {
  api_token = var.cloudflare.api_token
}

provider "kubernetes" {
  host                   = talos_cluster_kubeconfig.this.kubernetes_client_configuration.host
  cluster_ca_certificate = base64decode(talos_cluster_kubeconfig.this.kubernetes_client_configuration.ca_certificate)
  client_certificate     = base64decode(talos_cluster_kubeconfig.this.kubernetes_client_configuration.client_certificate)
  client_key             = base64decode(talos_cluster_kubeconfig.this.kubernetes_client_configuration.client_key)
}

provider "helm" {
  kubernetes = {
  host                   = talos_cluster_kubeconfig.this.kubernetes_client_configuration.host
  cluster_ca_certificate = base64decode(talos_cluster_kubeconfig.this.kubernetes_client_configuration.ca_certificate)
  client_certificate     = base64decode(talos_cluster_kubeconfig.this.kubernetes_client_configuration.client_certificate)
  client_key             = base64decode(talos_cluster_kubeconfig.this.kubernetes_client_configuration.client_key)
  }
}

provider "dns" {
  update {
    server        = var.dns.ns1
    key_name      = "ddnskey."
    key_algorithm = "hmac-sha256"
    key_secret    = var.dns.tsig_key
  }
}