data "http" "publicIp" {
  url = "https://ipv4.icanhazip.com"
}

resource "cloudflare_dns_record" "root_record" {
  name    = var.cloudflare.domain
  zone_id = var.cloudflare.dns_zone_id
  type    = "A"
  content = data.http.publicIp.response_body
  ttl     = 1
}
