data "aws_caller_identity" "this" {}

data "aws_subnets" "this" {
  filter {
    name   = "cidr-block"
    values = var.circuit["transit_subnet_cidrs"]
  }
}

data "aws_route_tables" "this" {
  filter {
    name   = "association.subnet-id"
    values = data.aws_subnets.this.ids
  }
}

data "equinix_ecx_l2_sellerprofile" "this" {
  name = "AWS Direct Connect"
}

resource "equinix_ecx_l2_connection" "this" {
  count = var.circuit["is_redundant"] ? 2 : 1

  name                = "${var.circuit["circuit_name"]}-${count.index + 1}"
  profile_uuid        = data.equinix_ecx_l2_sellerprofile.this.id
  speed               = var.circuit["speed_in_mbit"]
  speed_unit          = "MB"
  notifications       = var.circuit["notifications"]
  device_uuid         = var.circuit["edge_uuid"][count.index]
  device_interface_id = var.circuit["edge_interface"][count.index]
  service_token       = var.circuit["metal_service_tokens"][count.index]
  seller_region       = var.circuit["csp_region"]
  seller_metro_code   = var.circuit["equinix_metrocode"]
  authorization_key   = data.aws_caller_identity.this.account_id

  timeouts {
    create = "20m"
    delete = "20m"
  }

  lifecycle {
    ignore_changes = all
  }
}

resource "aws_dx_connection_confirmation" "this" {
  count = var.circuit["is_redundant"] ? 2 : 1

  connection_id = one([for action_data in one(equinix_ecx_l2_connection.this[count.index].actions).required_data : action_data["value"] if action_data["key"] == "awsConnectionId"])
}

resource "aws_vpn_gateway" "this" {
  amazon_side_asn = var.circuit["vpc_asn"]
  tags = {
    Name = "${var.circuit["circuit_name"]}-gateway"
  }
}

resource "aws_vpn_gateway_route_propagation" "this" {
  for_each = toset(data.aws_route_tables.this.ids)

  vpn_gateway_id = aws_vpn_gateway.this.id
  route_table_id = each.value
}

resource "aws_vpn_gateway_attachment" "this" {
  vpc_id         = var.circuit["vpc_id"]
  vpn_gateway_id = aws_vpn_gateway.this.id
}

resource "aws_dx_private_virtual_interface" "this" {
  count = var.circuit["is_redundant"] ? 2 : 1

  connection_id  = aws_dx_connection_confirmation.this[count.index].id
  name           = "${equinix_ecx_l2_connection.this[count.index].name}-pvif"
  vlan           = equinix_ecx_l2_connection.this[count.index].zside_vlan_stag
  address_family = "ipv4"
  bgp_asn        = 64512
  bgp_auth_key   = var.circuit["bgp_auth_key"]
  vpn_gateway_id = aws_vpn_gateway.this.id

  timeouts {
    create = "20m"
    delete = "20m"
  }

  lifecycle {
    ignore_changes = all
  }
}