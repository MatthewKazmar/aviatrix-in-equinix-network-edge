variable "edge" {
  type = object({
    gw_name                   = string,
    site_id                   = optional(string, ""),
    redundant                 = optional(bool, false),
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
    notifications             = list(string),
    equinix_fabric = optional(map(object({
      speed                = number,
      cloud_type           = number,
      transit_gw           = string,
      vpc_id               = string,
      transit_subnet_cidrs = list(string),
      csp_region           = string
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

  transit_gws    = [for k, v in var.edge["equinix_fabric"] : v.transit_gw]
  transit_gws_ha = var.edge["redundant"] ? local.transit_gws : []

  aws_transit_gws   = { for k, v in var.edge["equinix_fabric"] : v.transit_gw => k if v.cloud_type == 1 }
  azure_transit_gws = { for k, v in var.edge["equinix_fabric"] : v.transit_gw => k if v.cloud_type == 8 }
  gcp_transit_gws   = { for k, v in var.edge["equinix_fabric"] : v.transit_gw => k if v.cloud_type == 4 }

  #Aviatrix Edge provider needs 2 DNS Server IPs, no more, no less. Fix if empty list or if only 1 passed.
  dns_server_ips = length(var.edge["dns_server_ips"]) == 0 ? ["8.8.8.8", "1.1.1.1"] : length(var.edge["dns_server_ips"]) == 1 ? [var.edge["dns_server_ips"][0], var.edge["dns_server_ips"][0]] : var.edge["dns_server_ips"]

  dx_output = try({ for k, v in module.directconnect : local.aws_transit_gws[k] =>
    {
      csp_peering_addresses           = v.csp_peering_addresses,
      customer_side_peering_addresses = v.customer_side_peering_addresses
    } }, {}
  )

  exr_output = try({ for k, v in module.expressroute : local.azure_transit_gws[k] =>
    {
      csp_peering_addresses           = v.csp_peering_addresses,
      customer_side_peering_addresses = v.customer_side_peering_addresses
    } }, {}
  )

  # gcp_output = try({ for k, v in module.cloudinterconnect : local.gcp_transit_gws[k] =>
  #   {
  #     csp_peering_addresses           = v.csp_peering_addresses,
  #     customer_side_peering_addresses = v.customer_side_peering_addresses
  #   } }, {}
  # )
}