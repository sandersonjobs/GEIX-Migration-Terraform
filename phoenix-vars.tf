# Params file for variables

# OpenStack Variables
variable "openstack_data" {
  type = "map"
  default = {
    region = "US-EAST2"
    use_octavia = "true"
    os_image_id = "6144e0a4-2610-4047-abb0-b728a6ef40a8"
    os_flavor_id = "094d126c-7ac7-49ad-afeb-53bee704ec93"
    os_flavor_name = "f1.c4m32"
  }
}

# Metadata Variables
variable "metadata" {
  type = "map"
  default = {
    uai = "UAI2008311"
    license = "none"
    env = "dev"
  }
}

# Network Variables
variable "network_data" {
  type = "map"
  default = {
    internal_network_name = "GEIX-ATL1-CRP1-Internal"
    private_network_name = "GEIX-ATL1-CRP1-Private-PRD05"
    private_network_subnet_id ="dcc1b79f-306c-4552-b237-a0d2ec8e1b81"
    network_proxy = "http://PITC-Zscaler-Americas-Alpharetta3PR.proxy.corporate.ge.com:80"
  }
}

# Chef Variables
variable "chef_data" {
  type = "map"
  default = {
    client_version = "15.0.300"
    chef_server_url = "https://chef-phoenix.vaios.digital.ge.com/organizations/rascl"
    chef_user = "502755251"
    recreate_client = true
    ssl_verify = ":verify_none"
  }
}

# Loadbalancer Variables
variable "loadbalancer_data" {
  type = "map"
  default = {
    lb_name = "phoenix-lb"
    desired_member_capacity = 1
    listener_name = "listener_http"
    listener_protocol = "TCP"
    listener_protocol_port = 80
    pool_name = "pool_http"
    pool_protocol = "TCP"
    pool_lb_method = "ROUND_ROBIN"
    member_protocol_port = 80
    monitor_name = "monitor_http"
    monitor_type = "TCP"
    monitor_delay = 2
    monitor_timeout = 2
    monitor_max_retries = 2

  }
}

# Random Local Variables (since lists and maps cannot coexist in a variable
locals {
  desired_appserver_count = 1
  appserver_name = "michael-phoenix-test-server"
  jenkins_server_name = "jenkins_pipeline-server"
  openstack_version = "~> 1.17"
  key_pair = "GEIX-Migration"
  dbag_enc_key = "${file("~/.ssh/dbag_enc_key.pub")}"
  os_migration_key = "${file("~/.ssh/os-geix-migration.pem")}"
  chef_service_key = "${file("~/.ssh/chef-service-account.pem")}"
  security_groups = ["ALL_ALL_inside_project+GE_Inbound_Common_ports", "PUB-Ingress", "default"]
  no_proxy = ["github.build.ge.com", "chef-phoenix.vaios.digital.ge.com", "github.com"]
  phoenix_run_list = ["role[phoenix]"]
  jenkins_run_list = ["cta_yum::default","deploy_phoenix_terraform::default"]
  chef_client_options = [ "chef_license 'accept'" ]
}