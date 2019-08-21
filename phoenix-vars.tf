# Params file for variables

### OpenStack Variables
variable "openstack_data" {
  default = {
    os_image_id = "6144e0a4-2610-4047-abb0-b728a6ef40a8"
    os_flavor_id = "094d126c-7ac7-49ad-afeb-53bee704ec93"
    os_flavor_name = "f1.c4m32"
  }
}

variable "metadata" {
  default = {
    uai = "UAI2008311"
    license = "none"
    env = "dev"
  }
}

variable "network_data" {
  default = {
    internal_network_name = "GEIX-ATL1-CRP1-Internal"
    private_network_name = "GEIX-ATL1-CRP1-Private-PRD05"
    network_proxy = "http://PITC-Zscaler-Americas-Alpharetta3PR.proxy.corporate.ge.com:80"
    no_proxy = ["github.build.ge.com", "chef-phoenix.vaios.digital.ge.com", "github.com"]

  }
}

variable "chef_data" {
  default = {
    client_version = "15.0.300"
    run_list = ["role[phoenix]"]
    chef_server_url = "https://chef-phoenix.vaios.digital.ge.com/organizations/rascl"
    chef_user = "502755251"
    recreate_client = true
    chef_client_options = [ "chef_license 'accept'" ]
    ssl_verify = ":verify_none"
  }
}

locals {
  key_pair = "667"
  os_migration_key = "${file("~/.ssh/os-geix-migration.pem")}"
  chef_service_key = "${file("~/.ssh/chef-service-account.pem")}"
  security_groups = ["a22861ac-6a1f-40d3-8114-2f76880cb9ee", "fbfa7825-1b83-4c3e-93ee-188c85224717", "d0ae75b4-76ec-46e1-8fbb-d9e257f936f5"]
}