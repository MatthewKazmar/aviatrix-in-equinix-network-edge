variable "gw_name" {
  description = "Edge gateway name."
  type        = string
  default     = "edge-equinix"
}

variable "redundant" {
  description = "Run Edge in A/A HA."
  type = bool
  default = false
}

variable "site_id" {
  description = "Site ID."
  type        = string
  default     = "Equinix"
}

variable "wan_interface_ip_prefix" {
  description = "WAN interface CIDR."
  type        = string
  default     = "192.168.11.101/24"
}

variable "wan_default_gateway_ip" {
  description = "WAN default gateway IP."
  type        = string
  default     = "192.168.11.254"
}

variable "lan_interface_ip_prefix" {
  description = "LAN interface CIDR."
  type        = string
  default     = "192.168.12.101/24"
}

variable "dns_server_ip" {
  description = "Primary DNS server IP."
  type        = string
  default     = "8.8.8.8"
}

variable "secondary_dns_server_ip" {
  description = "Primary DNS server IP."
  type        = string
  default     = "8.8.4.4"
}

variable "local_as_number" {
  description = "BGP AS Number to assign to Edge as a Spoke."
  type        = string
  default     = null
}

variable "metro_code" {
  description = "Metro location."
  type        = string
  default     = "NY"
}

variable "create_acl" {
  description = "Set to true to create a new ACL."
  type        = bool
  default     = false
}

variable "acl_template_id" {
  description = "Existing ACL template ID."
  type        = string
  default     = null
}

variable "acl_name" {
  description = "ACL name."
  type        = string
  default     = "my-access-list"
}

variable "acl_description" {
  description = "ACL description."
  type        = string
  default     = "ACL description."
}

variable "type_code" {
  description = "Vendor package code."
  type        = string
  default     = "AVIATRIX_EDGE"
}

variable "core_count" {
  description = "Number of CPU cores used by device."
  type        = number
  default     = 2
}

variable "package_code" {
  description = "Software package code."
  type        = string
  default     = "STD"
}

variable "device_version" {
  description = "Vendor software version."
  type        = string
  default     = "6.9"
}

# variable "device_name" {
#   description = "Equinix Network device name."
#   type        = string
#   default     = ""
# }

# variable "device_hostname" {
#   description = "Equinix Network device hostname."
#   type        = string
#   default     = ""
# }

variable "notifications" {
  description = "List of email addresses that will receive device status notifications."
  type        = list(string)
  default     = ["myemail@equinix.com"]
}

variable "term_length" {
  description = "Device term length in months."
  type        = number
  default     = 1
}

variable "transit_gw_attachment" {
  description = "Transit gateways to attach to."
  type = list(string)
  default = []
}

locals {
  device_name = coalesce(var.device_name, var.gw_name)
  device_hostname = coalesce(var.device_hostname, var.device_name, var.gw_name)
  
  count = var.ha ? 1 : 2

}