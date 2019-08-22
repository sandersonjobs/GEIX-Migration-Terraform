## File to create loadbalancer and associated components


# Create Floating IP for Loadbalancer
resource "openstack_networking_floatingip_v2" "phoenix-lb_fip" {
  pool = "${var.network_data["internal_network_name"]}"
  description = "Loadbalancer Floating IP"
}

# Associate LB FIP with LB
resource "openstack_networking_floatingip_associate_v2" "attach_phoenix-lb_fip" {
  floating_ip = "${openstack_networking_floatingip_v2.phoenix-lb_fip.address}"
  port_id     = "${openstack_lb_loadbalancer_v2.phoenix-lb.vip_port_id}"
}

# Create Phoenix Loadbalancer
resource "openstack_lb_loadbalancer_v2" "phoenix-lb" {
  vip_subnet_id = "${var.network_data["private_network_subnet_id"]}"
  name = "${var.loadbalancer_data["lb_name"]}"
  region     = "${var.openstack_data["region"]}"
  depends_on      = [
    "openstack_compute_instance_v2.phoenix-server",
  ]
}

# Create listener
resource "openstack_lb_listener_v2" "phoenix-lb_listener" {
  name            = "${var.loadbalancer_data["listener_name"]}"
  protocol        = "${var.loadbalancer_data["listener_protocol"]}"
  protocol_port   = "${var.loadbalancer_data["listener_protocol_port"]}"
  loadbalancer_id = "${openstack_lb_loadbalancer_v2.phoenix-lb.id}"
  depends_on      = [
      "openstack_lb_loadbalancer_v2.phoenix-lb",
    ]
}

# Set methode for load balance charge between instance
resource "openstack_lb_pool_v2" "phoenix-lb_pool" {
  name            = "${var.loadbalancer_data["pool_name"]}"
  protocol        = "${var.loadbalancer_data["pool_protocol"]}"
  lb_method       = "${var.loadbalancer_data["pool_lb_method"]}"
  listener_id     = "${openstack_lb_listener_v2.phoenix-lb_listener.id}"
  depends_on      = [
      "openstack_lb_listener_v2.phoenix-lb_listener",
    ]
}

# Add multip instances to pool
resource "openstack_lb_member_v2" "phoenix-lb_member" {
  count           = "${var.loadbalancer_data["desired_member_capacity"]}"
  address         = "${element(openstack_compute_instance_v2.phoenix-server.*.access_ip_v4, count.index)}"
  protocol_port   = "${var.loadbalancer_data["member_protocol_port"]}"
  pool_id         = "${openstack_lb_pool_v2.phoenix-lb_pool.id}"
  subnet_id       = "${var.network_data["private_network_subnet_id"]}"
  depends_on      = [
      "openstack_lb_pool_v2.phoenix-lb_pool",
    ]
}

# Create health monitor for check services instances status
resource "openstack_lb_monitor_v2" "phoenix-lb_monitor" {
  name            = "${var.loadbalancer_data["monitor_name"]}"
  pool_id         = "${openstack_lb_pool_v2.phoenix-lb_pool.id}"
  type            = "${var.loadbalancer_data["monitor_type"]}"
  delay           = "${var.loadbalancer_data["monitor_delay"]}"
  timeout         = "${var.loadbalancer_data["monitor_timeout"]}"
  max_retries     = "${var.loadbalancer_data["monitor_max_retries"]}"
  depends_on      = [
      "openstack_lb_member_v2.phoenix-lb_member",
    ]
}
