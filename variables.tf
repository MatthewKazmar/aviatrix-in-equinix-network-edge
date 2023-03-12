variable "edge" {
  type = object({
    gw_name                   = string,
    site_id                   = optional(string, ""),
    redundant                 = optional(string, false),
    wan_interface_ip_prefixes = list(string),
    wan_default_gateway_ip    = string,
    lan_interface_ip_prefixes = list(string),
    dns_server_ips            = optional(list(string), ["8.8.8.8", "1.1.1.1"])
    customer_side_asn         = number,
    metro_code                = string,
    type_code                 = optional(string, "AVIATRIX_EDGE"),
    package_code              = optional(string, "STD")
    device_version            = optional(string, "6.9"),
    core_count                = optional(number, 2),
    term_length               = optional(number, 1),
    notifications             = list(string)
    equinix_fabric = optional(map(object({
      speed      = number,
      transit_gw = string,
    })), {})
  })
}

variable "equinix_edge_intermediary" {
  type = object({
    edge_uuid            = optional(list(string), []),
    edge_interface       = optional(number, null),
    metal_service_tokens = optional(list(string), [])
  })
}

locals {
  gw_names        = [var.edge["gw_name"], "${var.edge["gw_name"]}-ha"]
  site_id         = coalesce(var.edge["site_id"], "equinix-${var.edge["metro_code"]}")
  acl_name        = "${var.edge["gw_name"]}-acl"
  acl_description = "ACL for ${var.edge["gw_name"]}, primary and ha (if deployed.)"

  transit_gws       = [for k, v in var.edge["equinix_fabric"] : v.transit_gw]
  aws_transit_gws   = { for k, v in var.edge["equinix_fabric"] : v.transit_gw => k if data.aviatrix_transit_gateway.this[v.transit_gw].cloud_type == 1 }
  azure_transit_gws = { for k, v in var.edge["equinix_fabric"] : v.transit_gw => k if data.aviatrix_transit_gateway.this[v.transit_gw] == 8 }
  gcp_transit_gws   = { for k, v in var.edge["equinix_fabric"] : v.transit_gw => k if data.aviatrix_transit_gateway.this[v.transit_gw] == 4 }

  #Aviatrix Edge provider needs 2 DNS Server IPs, no more, no less. Fix if empty list or if only 1 passed.
  dns_server_ips = length(var.edge["dns_server_ips"]) == 0 ? ["8.8.8.8", "1.1.1.1"] : length(var.edge["dns_server_ips"]) == 1 ? [var.edge["dns_server_ips"][0], var.edge["dns_server_ips"][0]] : var.edge["dns_server_ips"]
}