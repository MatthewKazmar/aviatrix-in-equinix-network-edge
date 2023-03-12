data "http" "myip" {
  url = "http://ifconfig.me"
}

resource "equinix_network_acl_template" "this" {
  name        = local.acl_name
  description = local.acl_description

  inbound_rule {
    subnet      = "${chomp(data.http.myip.response_body)}/32"
    protocol    = "IP"
    src_port    = "any"
    dst_port    = "any"
    description = "Inbound from my IP"
  }
}