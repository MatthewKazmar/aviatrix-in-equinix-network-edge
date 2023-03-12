# data "aviatrix_transit_gateway" "this" {
#   for_each = toset(local.transit_gws)

#   gw_name = each.value
# }

resource "aviatrix_edge_spoke" "this" {
  count = var.edge["redundant"] ? 2 : 1

  # mandatory
  gw_name                        = local.gw_names[count.index]
  site_id                        = local.site_id
  management_interface_config    = "Static"
  management_interface_ip_prefix = "192.168.10.101/24"
  management_default_gateway_ip  = "192.168.10.254"
  wan_interface_ip_prefix        = var.edge["wan_interface_ip_prefixes"][count.index]
  wan_default_gateway_ip         = var.edge["wan_default_gateway_ip"]
  lan_interface_ip_prefix        = var.edge["lan_interface_ip_prefixes"][count.index]
  dns_server_ip                  = local.dns_server_ips[0]
  secondary_dns_server_ip        = local.dns_server_ips[1]
  ztp_file_type                  = "cloud-init"
  ztp_file_download_path         = "."
  local_as_number                = var.edge["customer_side_asn"]

  # advanced options - optional

  #   prepend_as_path                  = var.prepend_as_path
  #   enable_learned_cidrs_approval    = var.enable_learned_cidrs_approval
  #   approved_learned_cidrs           = var.approved_learned_cidrs
  #   spoke_bgp_manual_advertise_cidrs = var.spoke_bgp_manual_advertise_cidrs
  #   enable_preserve_as_path          = var.enable_preserve_as_path
  #   bgp_polling_time                 = var.bgp_polling_time
  #   bgp_hold_time                    = var.bgp_hold_time
  #   enable_edge_transitive_routing   = var.enable_edge_transitive_routing
  #   enable_jumbo_frame               = var.enable_jumbo_frame
  #   latitude                         = var.latitude
  #   longitude                        = var.longitude

  lifecycle {
    ignore_changes = [management_egress_ip_prefix]
  }
}

data "local_file" "this" {
  count = var.edge["redundant"] ? 2 : 1

  filename = "./${aviatrix_edge_spoke.this[count.index].gw_name}-${local.site_id}-cloud-init.txt"
}

data "equinix_network_account" "this" {
  metro_code = var.edge["metro_code"]
}

resource "equinix_network_file" "this" {
  count = var.edge["redundant"] ? 2 : 1

  metro_code       = data.equinix_network_account.this.metro_code
  byol             = true
  self_managed     = true
  device_type_code = var.edge["type_code"]
  process_type     = "CLOUD_INIT"
  file_name        = split("/", data.local_file.this[0].filename)[1]
  content          = data.local_file.this[count.index].content

  lifecycle {
    ignore_changes = all
  }
}

resource "equinix_network_device" "this" {
  metro_code         = data.equinix_network_account.this.metro_code
  account_number     = data.equinix_network_account.this.number
  type_code          = var.edge["type_code"]
  byol               = true
  self_managed       = true
  core_count         = var.edge["core_count"]
  package_code       = var.edge["package_code"]
  version            = var.edge["device_version"]
  name               = local.gw_names[0]
  notifications      = var.edge["notifications"]
  term_length        = var.edge["term_length"]
  cloud_init_file_id = equinix_network_file.this[0].uuid
  acl_template_id    = equinix_network_acl_template.this.id

  dynamic "secondary_device" {
    for_each = var.edge["redundant"] ? [1] : []
    content {
      name               = local.gw_names[1]
      metro_code         = data.equinix_network_account.this.metro_code
      account_number     = data.equinix_network_account.this.number
      notifications      = var.edge["notifications"]
      cloud_init_file_id = equinix_network_file.this[1].uuid
      acl_template_id    = equinix_network_acl_template.this.id
    }
  }
}

module "directconnect" {
  for_each = local.aws_transit_gws

  source = "./modules/directconnect"

  circuit = {
    is_redundant         = var.edge["redundant"],
    circuit_name         = each.value
    vpc_id               = var.edge["equinix_fabric"][each.value]["vpc_id"]
    csp_region           = var.edge["equinix_fabric"][each.value]["vpc_reg"]
    transit_subnet_cidrs = var.edge["equinix_fabric"][each.value]["transit_subnet_cidrs"]
    speed_in_mbit        = var.edge["equinix_fabric"][each.value]["speed"]
    equinix_metrocode    = var.edge["metro_code"]
    customer_side_asn    = var.edge["customer_side_asn"]
    edge_uuid            = coalescelist(var.equinix_edge_intermediary["edge_uuid"], equinix_network_device.this[*].id)
    edge_interface       = coalesce(var.equinix_edge_intermediary["edge_interface"], index(keys(var.edge["equinix_fabric"]), each.key) + 3)
    metal_service_tokens = var.equinix_edge_intermediary["metal_service_tokens"]
    notifications        = var.edge["notifications"]
  }
}

module "expressroute" {
  for_each = local.azure_transit_gws

  source = "./modules/expressroute"

  circuit = {
    is_redundant         = var.edge["redundant"],
    circuit_name         = each.value
    vpc_id               = var.edge["equinix_fabric"][each.value]["vpc_id"]
    csp_region           = var.edge["equinix_fabric"][each.value]["vpc_reg"]
    transit_subnet_cidrs = var.edge["equinix_fabric"][each.value]["transit_subnet_cidrs"]
    speed_in_mbit        = var.edge["equinix_fabric"][each.value]["speed"]
    equinix_metrocode    = var.edge["metro_code"]
    customer_side_asn    = var.edge["customer_side_asn"]
    edge_uuid            = coalescelist(var.equinix_edge_intermediary["edge_uuid"], equinix_network_device.this[*].id)
    edge_interface       = coalesce(var.equinix_edge_intermediary["edge_interface"], index(keys(var.edge["equinix_fabric"]), each.key) + 3)
    metal_service_tokens = var.equinix_edge_intermediary["metal_service_tokens"]
    notifications        = var.edge["notifications"]
  }
}

# GCP Terraform Provider for Interconnect is currently broken.
# See the submodule for details.

# module "cloudinterconnect" {
#   for_each = local.gcp_transit_gws

#   source = "./modules/cloudinterconnect"

#   circuit = {
#     is_redundant         = var.edge["redundant"],
#     circuit_name         = each.value
#     vpc_id               = var.edge["equinix_fabric"][each.value]["vpc_id"]
#     csp_region           = var.edge["equinix_fabric"][each.value]["vpc_reg"]
#     speed_in_mbit        = var.edge["equinix_fabric"][each.value]["transit_subnet_cidrs"]
#     equinix_metrocode    = var.edge["metro_code"]
#     customer_side_asn    = var.edge["customer_side_asn"]
#     edge_uuid            = coalescelist(var.equinix_edge_intermediary["edge_uuid"], equinix_network_device.this[*].id)
#     edge_interface       = coalesce(var.equinix_edge_intermediary["edge_interface"], index(keys(var.edge["equinix_fabric"]), each.key) + 3)
#     metal_service_tokens = var.equinix_edge_intermediary["metal_service_tokens"]
#     notifications        = var.edge["notifications"]
#   }
# }


resource "aviatrix_edge_spoke_transit_attachment" "edge_attachment" {
  for_each = toset(local.transit_gws)

  spoke_gw_name   = aviatrix_edge_spoke.this[0].gw_name
  transit_gw_name = each.value

  number_of_retries = 3
}

resource "aviatrix_edge_spoke_transit_attachment" "edge_attachment_ha" {
  for_each = toset(local.transit_gws_ha)

  spoke_gw_name   = aviatrix_edge_spoke.this[1].gw_name
  transit_gw_name = each.value

  number_of_retries = 3
}