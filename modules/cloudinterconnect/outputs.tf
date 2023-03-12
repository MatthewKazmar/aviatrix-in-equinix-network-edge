output "csp_peering_addresses" {
  description = "CSP side peering addresses."
  value       = google_compute_interconnect_attachment.this[*].cloud_router_ip_address
}

output "customer_side_peering_addresses" {
  description = "Customer (Equinix Metal/Edge/Colo) side peering addresses."
  value       = google_compute_interconnect_attachment.this[*].customer_router_ip_address
}

output "customer_side_vlan_tags" {
  description = "Customer (Equinix Metal/Edge/Colo) vlans."
  value       = equinix_ecx_l2_connection.this[*].zside_vlan_stag
}