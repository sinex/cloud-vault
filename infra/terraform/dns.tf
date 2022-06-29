data "cloudflare_zone" "domain" {
  name = var.cloudflare_zone
}

resource "cloudflare_record" "vault" {
  zone_id = data.cloudflare_zone.domain.id
  name    = var.hostname
  value   = oci_core_instance.instance0.public_ip
  type    = "A"
  ttl     = 3600
  proxied = false
}
