output "csp_peering_addresses" {
  description = "CSP side peering addresses."
  value       = [cidrhost(azurerm_express_route_circuit_peering.this.primary_peer_address_prefix, 2), cidrhost(azurerm_express_route_circuit_peering.this.secondary_peer_address_prefix, 2)]
}

output "customer_side_peering_addresses" {
  description = "Equinix side peering addresses."
  value       = [cidrhost(azurerm_express_route_circuit_peering.this.primary_peer_address_prefix, 1), cidrhost(azurerm_express_route_circuit_peering.this.secondary_peer_address_prefix, 1)]
}

output "customer_side_vlan_tags" {
  description = "Customer (Equinix Metal/Edge/Colo) vlans."
  value       = [equinix_ecx_l2_connection.this.zside_vlan_stag]
}