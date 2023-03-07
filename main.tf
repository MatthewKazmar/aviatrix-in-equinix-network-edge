resource "aviatrix_edge_spoke" "this" {
  count = var.redundant ? 2 : 1

  # mandatory
  gw_name                        = count == 0 ? var.gw_name : "${var.gw_name}-hagw"
  site_id                        = var.site_id
  management_interface_config    = "Static"
  management_interface_ip_prefix = "192.168.10.101/24"
  management_default_gateway_ip  = "192.168.10.254"
  wan_interface_ip_prefix        = var.wan_interface_ip_prefix[count]
  wan_default_gateway_ip         = var.wan_default_gateway_ip
  lan_interface_ip_prefix        = var.lan_interface_ip_prefix[count]
  dns_server_ip                  = var.management_interface_config == "Static" ? var.dns_server_ip : null
  secondary_dns_server_ip        = var.management_interface_config == "Static" ? var.secondary_dns_server_ip : null
  ztp_file_type                  = "cloud-init"
  ztp_file_download_path         = "."

  # advanced options - optional
  local_as_number = var.local_as_number
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
  count = var.redundant ? 2 : 1

  filename = "${aviatrix_edge_spoke.this.ztp_file_download_path}/${aviatrix_edge_spoke.this.gw_name}-${aviatrix_edge_spoke.this.site_id}-${count}-cloud-init.txt"
}

data "equinix_network_account" "this" {
  metro_code = var.metro_code
}

resource "equinix_network_file" "this" {
  count = var.redundant ? 2 : 1

  metro_code       = data.equinix_network_account.this.metro_code
  byol             = true
  self_managed     = true
  device_type_code = var.type_code
  process_type     = "CLOUD_INIT"
  file_name        = "${aviatrix_edge_spoke.this.gw_name}-${aviatrix_edge_spoke.this.site_id}-${count}-cloud-init.txt"
  content          = data.local_file.this[count].content

  lifecycle {
    ignore_changes = all
  }
}

resource "equinix_network_device" "this" {
  count = var.redundant ? 2 : 1

  metro_code         = data.equinix_network_account.this.metro_code
  account_number     = data.equinix_network_account.this.number
  type_code          = var.type_code
  byol               = true
  self_managed       = true
  core_count         = var.core_count
  package_code       = var.package_code
  version            = var.device_version
  name               = count == 0 ? var.gw_name : "${var.gw_name}-hagw"
  notifications      = var.notifications
  term_length        = var.term_length
  cloud_init_file_id = equinix_network_file.this.uuid
  acl_template_id    = local.acl_template_id
}

resource "aviatrix_edge_spoke_transit_attachment" "edge_attachment" {
  for_each = toset(var.transit_gw_attachment)

  spoke_gw_name   = aviatrix_edge_spoke.this[0].gw_name
  transit_gw_name = each.value

  number_of_retries = 3
}

resource "aviatrix_edge_spoke_transit_attachment" "edge_attachment_ha" {
  count = var.redundant ? 1 : 0

  for_each = toset(var.transit_gw_attachment)

  spoke_gw_name   = aviatrix_edge_spoke.this[1].gw_name
  transit_gw_name = each.value

  number_of_retries = 3
}

locals {
  acl_template_id = var.create_acl ? equinix_network_acl_template.this[0].id : var.acl_template_id
}