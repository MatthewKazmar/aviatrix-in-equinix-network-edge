variable "circuit" {
  type = object({
    is_redundant                   = bool,
    circuit_name                   = string,
    vpc_id                         = string,
    azure_vnet_gateway_subnet_cidr = optional(string, null),
    azure_exr_use_2nd_location     = optional(bool, false),
    csp_region                     = string
    equinix_metrocode              = string,
    speed_in_mbit                  = string,
    edge_uuid                      = optional(list(string), [null, null]),
    edge_interface                 = optional(number, null),
    metal_service_tokens           = optional(list(string), [null, null]),
    customer_side_asn              = number,
    bgp_auth_key                   = optional(string, "aviatrix1234#!"),
    notifications                  = list(string)
  })
}

locals {
  vnet_name = split(":", var.circuit["vpc_id"])[0]
  vnet_rg   = split(":", var.circuit["vpc_id"])[1]

  peering_cidr  = cidrsubnet("169.254.0.0/16", 13, random_integer.peering_cidr.result)
  peering_cidrs = [cidrsubnet(local.peering_cidr, 1, 0), cidrsubnet(local.peering_cidr, 1, 1)]

  azure_vnet_gateway_subnet_cidr = coalesce(var.circuit["azure_vnet_gateway_subnet_cidr"], cidrsubnet(data.azurerm_virtual_network.this.address_space[0], 4, 15), "none") #Grab last /27 in a /23

  exr_peering_location1 = lookup(local.exr_location_lookup, var.circuit["equinix_metrocode"])
  exr_peering_location2 = coalesce(lookup(local.exr_location_lookup, "${var.circuit["equinix_metrocode"]}2", null), local.exr_peering_location1)

  exr_peering_location = var.circuit["azure_exr_use_2nd_location"] ? local.exr_peering_location2 : local.exr_peering_location1

  #Microsoft sometimes changes the Metro locations and it isn't reflected in Equinix Seller Profiles. Also, secondary locations.
  exr_location_lookup = {
    "HK"  = "Hong Kong SAR",
    "LA"  = "Los Angeles2",
    "LA2" = "Los Angeles2"
    "AM"  = "Amsterdam",
    "AM"  = "Amsterdam2",
    "AT"  = "Atlanta",
    #"" = "Berlin",
    "BG"  = "Bogota",
    "CA"  = "Canberra2",
    "CH"  = "Chicago",
    "DA"  = "Dallas",
    "DX"  = "Dubai2",
    "DB"  = "Dublin",
    "FR"  = "Frankfurt",
    "FR2" = "Frankfurt2",
    "GV"  = "Geneva",
    "HK"  = "Hong Kong SAR",
    "HK2" = "Hong Kong2",
    "LD"  = "London",
    "LD"  = "London2",
    "LA"  = "Los Angeles2",
    "LA2" = "Los Angeles2",
    "ME"  = "Melbourne",
    "MI"  = "Miami",
    "ML"  = "Milan",
    "NY"  = "New York",
    "OS"  = "Osaka",
    "PA"  = "Paris",
    "PA2" = "Paris2",
    "PE"  = "Perth",
    #"" = "Quebec City",
    "RJ"  = "Rio de Janeiro",
    "SP"  = "Sao Paulo",
    "SE"  = "Seattle",
    "sl"  = "Seoul",
    "SV"  = "Silicon Valley",
    "SG"  = "Singapore",
    "SG2" = "Singapore2",
    "SK"  = "Stockholm",
    "SY"  = "Sydney",
    "TY"  = "Tokyo",
    "TY2" = "Tokyo2",
    "TR"  = "Toronto",
    "DC"  = "Washington DC",
    "ZH"  = "Zurich"
  }
}