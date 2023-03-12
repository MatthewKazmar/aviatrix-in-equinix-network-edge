output "aviatrix_edge_spoke" {
  value = aviatrix_edge_spoke.this
}

output "equinix_network_device" {
  value = equinix_network_device.this
}

output "equinix_fabric" {
  value = merge(local.dx_output, local.exr_output)
  #value = merge(local.dx_output, local.exr_output, local.gcp_output)
}