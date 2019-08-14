# Create port for static IP for LB
resource "openstack_networking_port_v2" "phoenix-lb_static_ip_port" {
  name = "phoenix-lb_static_ip_port"
  network_id = "2d4168b2-0c5d-450a-85cc-bcaf8bc6d2b4"
  admin_state_up = "true"
  fixed_ip {
    subnet_id = "bd6e5922-b179-4f18-b499-9e76efa290ae",
    ip_address = "10.153.16.50"
  }

}
# Create Phoenix Loadbalancer
resource "openstack_lb_loadbalancer_v2" "phoenix-lb" {
  vip_subnet_id = "bd6e5922-b179-4f18-b499-9e76efa290ae"
  name = "phoenix-lb"
  region     = "US-EAST2"
  vip_address = "${openstack_networking_port_v2.phoenix-lb_static_ip_port.fixed_ip}"
  depends_on      = [
    "openstack_compute_instance_v2.phoenix-server",
    #"openstack_networking_port_v2.phoenix-lb_static_ip_port"
  ]
}

# Create listener
resource "openstack_lb_listener_v2" "phoenix-lb_listener" {
  name            = "listener_http"
  protocol        = "TCP"
  protocol_port   = 80
  loadbalancer_id = "${openstack_lb_loadbalancer_v2.phoenix-lb.id}"
  depends_on      = [
      "openstack_lb_loadbalancer_v2.phoenix-lb",
    ]
}

# Set methode for load balance charge between instance
resource "openstack_lb_pool_v2" "phoenix-lb_pool" {
  name            = "pool_http"
  protocol        = "TCP"
  lb_method       = "ROUND_ROBIN"
  listener_id     = "${openstack_lb_listener_v2.phoenix-lb_listener.id}"
  depends_on      = [
      "openstack_lb_listener_v2.phoenix-lb_listener",
    ]
}

# Add multip instances to pool
resource "openstack_lb_member_v2" "phoenix-lb_member" {
  count           = 1
  #count           = "${var.desired_capacity_http}"
  address         = "${element(openstack_compute_instance_v2.phoenix-server.*.access_ip_v4, count.index)}"
  protocol_port   = 80
  pool_id         = "${openstack_lb_pool_v2.phoenix-lb_pool.id}"
  subnet_id       = "bd6e5922-b179-4f18-b499-9e76efa290ae"
  depends_on      = [
      "openstack_lb_pool_v2.phoenix-lb_pool",
    ]
}

# Create health monitor for check services instances status
resource "openstack_lb_monitor_v2" "phoenix-lb_monitor" {
  name            = "monitor_http"
  pool_id         = "${openstack_lb_pool_v2.phoenix-lb_pool.id}"
  type            = "TCP"
  delay           = 2
  timeout         = 2
  max_retries     = 2
  depends_on      = [
      "openstack_lb_member_v2.phoenix-lb_member",
    ]
}
