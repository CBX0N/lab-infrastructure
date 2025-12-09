variable "cloudflare" {
  type = object({
    api_token   = string
    dns_zone_id = string
    domain      = string
  })
}

variable "cloud_init" {
  type = object({
    username             = string
    user_hashed_password = string
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
    private_key  = string
    user         = string
    host         = string
    token_id     = string
    token_secret = string
  })
}

variable "ubuntu_template" {
  type = object({
    image = string
  })
}