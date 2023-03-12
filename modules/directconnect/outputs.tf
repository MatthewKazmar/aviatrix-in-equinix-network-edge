output "csp_peering_addresses" {
  description = "CSP side peering addresses."
  value       = aws_dx_private_virtual_interface.this[*].amazon_address
}

output "customer_side_peering_addresses" {
  description = "Equinix side peering addresses."
  value       = aws_dx_private_virtual_interface.this[*].customer_address
}

output "customer_side_vlan_tags" {
  description = "Customer (Equinix Metal/Edge/Colo) vlans."
  value       = equinix_ecx_l2_connection.this[*].zside_vlan_stag
}