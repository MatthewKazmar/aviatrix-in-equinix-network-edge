data "azurerm_virtual_network" "this" {
  name                = local.vnet_name
  resource_group_name = local.vnet_rg
}

data "equinix_ecx_l2_sellerprofile" "this" {
  name = "Azure ExpressRoute"
}

resource "random_integer" "vlan" {
  min = 100
  max = 1000
}

resource "random_integer" "peering_cidr" {
  min = 0
  max = 8191
}

resource "azurerm_express_route_circuit" "this" {
  resource_group_name   = local.vnet_rg
  name                  = var.circuit["circuit_name"]
  location              = var.circuit["csp_region"]
  service_provider_name = "Equinix"
  peering_location      = lookup(local.exr_location_lookup, var.circuit["equinix_metrocode"])
  bandwidth_in_mbps     = var.circuit["speed"]

  sku {
    tier   = "Standard"
    family = "MeteredData"
  }

  allow_classic_operations = false
}

resource "azurerm_express_route_circuit_peering" "this" {
  resource_group_name           = local.vnet_rg
  express_route_circuit_name    = azurerm_express_route_circuit.this.name
  peering_type                  = "AzurePrivatePeering"
  peer_asn                      = var.circuit["customer_side_asn"]
  primary_peer_address_prefix   = local.peering_cidrs[0]
  secondary_peer_address_prefix = local.peering_cidrs[1]
  vlan_id                       = random_integer.vlan.result
  shared_key                    = var.circuit["bgp_auth_key"]
}

resource "azurerm_public_ip" "this" {
  resource_group_name = local.vnet_rg
  location            = var.circuit["csp_region"]
  name                = "${var.circuit["circuit_name"]}-pip"
  sku                 = "Basic"
  allocation_method   = "Dynamic"
}

resource "azurerm_subnet" "this" {
  name                 = "GatewaySubnet"
  resource_group_name  = local.vnet_rg
  virtual_network_name = local.vnet_name

  address_prefixes = [local.azure_vnet_gateway_subnet_cidr]

}

resource "azurerm_virtual_network_gateway" "this" {
  resource_group_name = local.vnet_rg
  location            = var.circuit["csp_region"]
  name                = "${var.circuit["circuit_name"]}-gateway"
  type                = "ExpressRoute"

  sku           = "Standard"
  active_active = false
  enable_bgp    = false

  ip_configuration {
    name                          = "default"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.this.id
    public_ip_address_id          = azurerm_public_ip.this.id
  }
}

resource "azurerm_virtual_network_gateway_connection" "this" {
  name                       = "${var.circuit["circuit_name"]}-gateway-connection"
  resource_group_name        = azurerm_virtual_network_gateway.this.resource_group_name
  location                   = azurerm_virtual_network_gateway.this.location
  type                       = "ExpressRoute"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.this.id
  express_route_circuit_id   = azurerm_express_route_circuit.this.id
}

resource "equinix_ecx_l2_connection" "this" {
  name                = "${var.circuit["circuit_name"]}-1"
  profile_uuid        = data.equinix_ecx_l2_sellerprofile.this.id
  speed               = var.circuit["speed"]
  speed_unit          = "MB"
  notifications       = var.circuit["notifications"]
  device_uuid         = var.circuit["edge_uuid"][0]
  device_interface_id = var.circuit["edge_interface"]
  service_token       = var.circuit["metal_service_tokens"][0]
  seller_region       = var.circuit["csp_region"]
  seller_metro_code   = var.circuit["equinix_metrocode"]
  authorization_key   = azurerm_express_route_circuit.this.service_key
  named_tag           = "private"

  dynamic "secondary_connection" {
    for_each = var.circuit["is_redundant"] ? [1] : []
    content {
      name                = "${var.circuit["circuit_name"]}-2"
      device_uuid         = var.circuit["edge_uuid"][1]
      device_interface_id = var.circuit["edge_interface"]
      service_token       = var.circuit["metal_service_tokens"][1]
    }
  }

  timeouts {
    create = "20m"
    delete = "20m"
  }

  lifecycle {
    ignore_changes = all
  }
}