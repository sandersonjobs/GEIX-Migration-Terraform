provider "openstack" {
  region     = "US-EAST2"
  version = "~> 1.17"
}

#resource "openstack_compute_keypair_v2" "keypair" {
#  name       = "GEIX-Migration"
#  #public_key = "${data.openstack_compute_keypair_v2.GEIX-Migration-Key.public_key}"
#  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDQvk6gveupF/5WPCBq4fJ0FhuhD7vMc1pWexhboyO+c2LOF+XAXjD10OVqnAoOmT6HVXwENdTp6+paIGpsfS+OLiU+/iXfmS/QOlJN8a7mVR2WKQ8KfHkodrPtflDl5CGNoK7NWkmhHxShvoTrrciCVua6LthZ7ADtUVyhYuhVCdDiDKnd6TMUjkJZy6mFlo0JDp6szCy/OlxMCV14Xpxh7OX+wc2izXvcDbk8torhjQzyQW6j55Er8f4a1I4uTau/zxhDU9VDSZLaPQiV1ZSrcE+vMOq5pPpmzlS6TwLdzST2TSGcQfFYzP7hkJcNFot16jYNfG4isu9ecKLqef8x"
#}

# Create a web server
resource "openstack_compute_instance_v2" "vm1" {
  count = "1"
  name = "byron-phoenix-test-server"
  image_id = "6144e0a4-2610-4047-abb0-b728a6ef40a8"
  flavor_id = "094d126c-7ac7-49ad-afeb-53bee704ec93"
  flavor_name = "f1.c4m32"
  key_pair = "GEIX-Migration"
  #key_pair = "${openstack_compute_keypair_v2.keypair.name}"
  security_groups = ["ALL_ALL_inside_project+GE_Inbound_Common_ports","PUB-Ingress","default"]

  network {
    name = "GEIX-ATL1-CRP1-Internal"
  }

  metadata {
    env = "dev"
    uai = "UAI2008311"
    license = "none"
  }

//  provisioner "remote-exec" {
//    inline = [
//      "sleep 30"
//    ]
//
//    connection {
//      type     = "ssh"
//      user     = "gecloud"
//      private_key = "${file("../.ssh/os-geix-migration.pem")}"
//    }
//  }

  provisioner "chef" {
//    attributes_json = <<EOF
//      {
//        "key": "value",
//        "app": {
//          "cluster1": {
//            "nodes": [
//              "webserver1",
//              "webserver2"
//            ]
//          }
//        }
//      }
//    EOF

    connection {
      type     = "ssh"
      user     = "gecloud"
      private_key = "${file("../.ssh/os-geix-migration.pem")}"
    }
    fetch_chef_certificates = true
    http_proxy      = "http://PITC-Zscaler-Americas-Alpharetta3PR.proxy.corporate.ge.com:80"
    https_proxy     = "http://PITC-Zscaler-Americas-Alpharetta3PR.proxy.corporate.ge.com:80"
<<<<<<< HEAD:phoenix-migration.tf
    no_proxy        = ["github.build.ge.com", "chef-phoenix.vaios.digital.ge.com", "github.com"]
    //run_list        = ["role[phoenix]"]
    run_list        = ["cta_yum::default","phoenix_install_cookbook::default@0.0.6"]
=======
    no_proxy        = ["github.build.ge.com", "chef-phoenix.vaios.digital.ge.com"]
    run_list        = ["role[phoenix]"]
    // to run a specific cookbook version
    //run_list        = ["cta_yum::default","phoenix_install_cookbook::default@0.0.6"]
>>>>>>> 2a157f31bbf1fcb81bcc03454117dc42ccccccca:test.tf
    node_name       = "${openstack_compute_instance_v2.vm1.name}"
    //secret_key      = "${file("../encrypted_data_bag_secret")}"
    server_url      = "https://chef-phoenix.vaios.digital.ge.com/organizations/rascl"
    recreate_client = true
    user_name       = "502755251"
    user_key        = "${file("../.ssh/chef-service-account.pem")}"
    client_options = [ "chef_license 'accept'" ]
    version         = "15.0.300"
    # If you have a self signed cert on your chef server change this to :verify_none
    ssl_verify_mode = ":verify_none"
  }

}
