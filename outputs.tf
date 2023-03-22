output "aviatrix_edge_spoke" {
  value = aviatrix_edge_spoke.this
}

output "equinix_network_device" {
  value = equinix_network_device.this
}

output "csp_connections" {
  value = local.csp_output
}