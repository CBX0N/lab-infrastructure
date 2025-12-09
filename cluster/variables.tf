variable "cloudflare" {
  type = object({
    api_token   = string
    dns_zone_id = string
    domain      = string
  })
}

variable "flux" {
  type = object({
    git_repository = string
    repo_tag       = string
    path           = string
    private_key    = string
    public_key     = string
    known_hosts    = string
  })
}

variable "talos_control_plane" {
  type = object({
    count              = number
    image              = string
    talos_version      = string
    kubernetes_version = string
    cluster_endpoint   = string
    boot_image         = string
  })
}

variable "dns" {
  type = object({
    zone     = string
    ns1      = string
    tsig_key = string
  })
}

variable "proxmox" {
  type = object({
    host         = string
    token_id     = string
    token_secret = string
  })
}