variable "circuit" {
  type = object({
    is_redundant         = bool,
    circuit_name         = string,
    vpc_id               = string,
    csp_region           = string
    equinix_metrocode    = string,
    speed_in_mbit        = string,
    edge_uuid            = optional(list(string), [null, null]),
    edge_interface       = optional(list(number), [null, null]),
    metal_service_tokens = optional(list(string), [null, null]),
    customer_side_asn    = number,
    bgp_auth_key         = optional(string, "aviatrix1234#!"),
    notifications        = list(string)
  })
}

locals {
  network = split("~-~", var.circuit["vpc_id"])[0]
  project = split("~-~", var.circuit["vpc_id"])[1]

  #Aviatrix GCP Gateway lists the zone in the vpc_reg attribute.
  csp_region = regex("[a-z]+-[a-z0-9]+", var.circuit["csp_region"])
}