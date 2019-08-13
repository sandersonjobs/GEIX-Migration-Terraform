# Create Floating IP for Phoenix Loadbalancer
resource "openstack_networking_floatingip_v2" "phoenix-lb_floatingip_1" {
  #address	= "192.168.0.4"
  pool		= "GEIX-ATL1-CRP1-Internal"
  fixed_ip	= "${openstack_lb_loadbalancer_v2.phoenix-lb.vip_address}"
  port_id = "${openstack_lb_loadbalancer_v2.phoenix-lb.id}"
  depends_on	= [
    "openstack_lb_loadbalancer_v2.phoenix-lb",
  ]
}

# Create Phoenix Loadbalancer
resource "openstack_lb_loadbalancer_v2" "phoenix-lb" {
  vip_subnet_id = "bd6e5922-b179-4f18-b499-9e76efa290ae"
  name = "phoenix-lb"
  region     = "US-EAST2"
  depends_on      = [
    "openstack_compute_instance_v2.phoenix-server"
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
