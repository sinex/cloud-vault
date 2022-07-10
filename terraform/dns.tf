data "cloudflare_zone" "domain" {
  name = var.cloudflare_zone
}

# DNS record will only be created for the primary instance
resource "cloudflare_record" "vault" {
  zone_id = data.cloudflare_zone.domain.id
  name    = var.hostname
  value   = oci_core_instance.instances["primary"].public_ip
  type    = "A"
  ttl     = 1
  proxied = true
}
