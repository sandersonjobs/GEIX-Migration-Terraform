provider "openstack" {
  region     = "US-EAST2"
  version = "~> 1.17"
  use_octavia = "true"
}

# Create a web server
resource "openstack_compute_instance_v2" "phoenix-server" {
  count = "1"
  name = "michael-phoenix-test-server"
  image_id = "6144e0a4-2610-4047-abb0-b728a6ef40a8"
  flavor_id = "094d126c-7ac7-49ad-afeb-53bee704ec93"
  flavor_name = "f1.c4m32"
  key_pair = "GEIX-Migration"
  security_groups = ["ALL_ALL_inside_project+GE_Inbound_Common_ports","PUB-Ingress","default"]

  network {
    name = "GEIX-ATL1-CRP1-Internal"
  }

  metadata {
    env = "dev"
    uai = "UAI2008311"
    license = "none"
  }

  provisioner "chef" {
    connection {
      type     = "ssh"
      user     = "gecloud"
      private_key = "${file("~/.ssh/os-geix-migration.pem")}"
    }
    fetch_chef_certificates = true
    http_proxy      = "http://PITC-Zscaler-Americas-Alpharetta3PR.proxy.corporate.ge.com:80"
    https_proxy     = "http://PITC-Zscaler-Americas-Alpharetta3PR.proxy.corporate.ge.com:80"
    no_proxy        = ["github.build.ge.com", "chef-phoenix.vaios.digital.ge.com", "github.com"]
    run_list        = ["role[phoenix]"]
    //run_list        = ["cta_yum::default","phoenix_install_cookbook::default@0.0.10"]
    node_name       = "${openstack_compute_instance_v2.phoenix-server.name}"
    server_url      = "https://chef-phoenix.vaios.digital.ge.com/organizations/rascl"
    recreate_client = true
    user_name       = "502755251"
    user_key        = "${file("~/.ssh/chef-service-account.pem")}"
    client_options = [ "chef_license 'accept'" ]
    version         = "15.0.300"
    # If you have a self signed cert on your chef server change this to :verify_none
    ssl_verify_mode = ":verify_none"
  }
}
