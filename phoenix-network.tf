# Network creation
resource "openstack_networking_network_v2" "phoenix-network" {
  name                = "GEIX-ATL1-CRP1-Internal-Phoenix"
}

#### HTTP SUBNET ####

# Subnet http configuration
resource "openstack_networking_subnet_v2" "phoenix-subnet" {
  #name                = "${var.network_http["subnet_name"]}"
  name                = "TSUBNET-GEIX-ATL1-CRP1-Internal-PRD01-Phoenix"
  network_id          = "${openstack_networking_network_v2.phoenix-network.id}"
  #cidr                = "${var.network_http["cidr"]}"
  cidr                = "10.153.17.0/24"
  gateway_ip		= "10.153.17.1"
  #dns_nameservers     = "${var.dns_ip}"
  dns_nameservers     = [
	"10.220.220.220i",
	"10.220.220.221",
	]
  depends_on            = [
    "${openstack_networking_subnet_v2.phoenix-network}",
  ]
}

# Router interface configuration
resource "openstack_networking_router_interface_v2" "phoenix-router" {
  name		= "NRTR01-GEIX-ATL1-CRP1-Private-PRD05-Phoenix"
  admin_state_up      = true
  external_network_id = "${openstack_networking_network_v2.phoenix-network.id}"
  subnet_id           = "${openstack_networking_network_v2.phoenix-subnet.id}"
  depends_on		= [
    "${openstack_networking_subnet_v2.phoenix-subnet}",
  ]
}
