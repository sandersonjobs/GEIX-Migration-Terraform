provider "openstack" {
  region     = "${var.openstack_data["region"]}"
  version = "~> 1.17"
  use_octavia = "${var.openstack_data["use_octavia"]}"
}

# Create a web server
resource "openstack_compute_instance_v2" "phoenix-server" {
  count = "${local.desired_appserver_count}"
  name = "${local.appserver_name}"
  image_id = "${var.openstack_data["os_image_id"]}"
  flavor_id = "${var.openstack_data["os_flavor_id"]}"
  flavor_name = "${var.openstack_data["os_flavor_name"]}"
  key_pair = "${local.key_pair}"
  security_groups = "${local.security_groups}"

  network {
    name = "${var.network_data["private_network_name"]}"
  }

  metadata {
    env = "${var.metadata["env"]}"
    uai = "${var.metadata["uai"]}"
    license = "${var.metadata["license"]}"
  }

  provisioner "chef" {
    connection {
      type     = "ssh"
      user     = "gecloud"
      private_key = "${local.os_migration_key}"
    }
    fetch_chef_certificates = true
    http_proxy      = "${var.network_data["network_proxy"]}"
    https_proxy     = "${var.network_data["network_proxy"]}"
    no_proxy        = "${local.no_proxy}"
    run_list        = "${local.run_list}"
    //run_list        = ["cta_yum::default","phoenix_install_cookbook::default@0.0.10"]
    node_name       = "${openstack_compute_instance_v2.phoenix-server.name}"
    server_url      = "${var.chef_data["chef_server_url"]}"
    recreate_client = "${var.chef_data["recreate_client"]}"
    user_name       = "${var.chef_data["chef_user"]}"
    user_key        = "${local.chef_service_key}"
    client_options = "${local.chef_client_options}"
    version         = "${var.chef_data["client_version"]}"
    # If you have a self signed cert on your chef server change this to :verify_none
    ssl_verify_mode = "${var.chef_data["ssl_verify"]}"
  }
}
