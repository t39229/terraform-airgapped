#Terraform provider
provider "google" {
  project     = "my-project"
  region      = "europe-west4"
  zone        = "europe-west4-c"
}

#Create pet.
resource "random_pet" "cluster" {
}

# -----------------------------------------------
# NETWORKING
# -----------------------------------------------
resource "google_compute_network" "air_gap_qa_network" {
  name                    = "air-gap-qa-network-${random_pet.cluster.id}"
  auto_create_subnetworks = "false" 
  routing_mode            = "GLOBAL"
}

resource "google_compute_subnetwork" "private_subnet" {
  name          = "private-subnet-${random_pet.cluster.id}"
  ip_cidr_range = "12.10.10.0/24"
  network       = google_compute_network.air_gap_qa_network.id
  region        = var.region

  private_ip_google_access = false
}

resource "google_compute_subnetwork" "public_subnet" {
  name          = "public-subnet-${random_pet.cluster.id}"
  ip_cidr_range = "12.20.10.0/24"
  network       = google_compute_network.air_gap_qa_network.id
  region        = var.region

  private_ip_google_access = true
}

resource "google_compute_address" "public_address" {
  name    = "public-address${random_pet.cluster.id}"
  region  = var.region
}

resource "google_compute_router" "public_router" {
  name    = "public-router${random_pet.cluster.id}"
  network = google_compute_network.air_gap_qa_network.id
}

resource "google_compute_router_nat" "public_nat" {
  name                               = "public-nat-${random_pet.cluster.id}"
  router                             = google_compute_router.public_router.name
  nat_ip_allocate_option             = "MANUAL_ONLY"
  nat_ips                            = [ google_compute_address.public_address.self_link ]
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS" 
  subnetwork {
    name                    = google_compute_subnetwork.public_subnet.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
  depends_on                         = [ google_compute_address.public_address ]
}

resource "google_compute_firewall" "allow-ssh" {
  name = "air-gap-qa-test-fw-allow-ssh-${random_pet.cluster.id}"
  network = google_compute_network.air_gap_qa_network.name
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "allow-https" {
  name = "air-gap-qa-test-fw-allow-https-${random_pet.cluster.id}"
  network = google_compute_network.air_gap_qa_network.name
  allow {
    protocol = "tcp"
    ports    = ["443"]
  }
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "allow-all" {
  allow {
    protocol = "all"
  }

  direction     = "INGRESS"
  name          = "air-gap-qa-test-fw-allow-all-${random_pet.cluster.id}"
  network       = google_compute_network.air_gap_qa_network.name
  priority      = "999"
  source_ranges = ["0.0.0.0/0"]
}

# -----------------------------------------------
# BASTION
# -----------------------------------------------
resource "google_compute_instance" "air_gap_qa_bastion" {
  name         = "air-gap-qa-${random_pet.cluster.id}-bastion"
  machine_type = "e2-small"
  metadata_startup_script = file("files/bastion_setup.sh")

  tags = ["${random_pet.cluster.id}-bastion"]

  
  scheduling {
    preemptible = false
    automatic_restart = false
    provisioning_model = "-"
    #on_host_maintenance = "TERMINATE"
  }

  boot_disk {
    initialize_params {
      size  = 250
      image = var.vm_image
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.public_subnet.name

    access_config {}
  }
  provisioner "remote-exec" {
    inline = [
      "cp /etc/ansible/ansible.cfg /home/bastion/ansible.cfg",
      "echo '[sudo_become_plugin]' >> /home/bastion/ansible.cfg",
      "echo 'flags = -H -S' >> /home/bastion/ansible.cfg"
    ]

    connection {
      host     = "${google_compute_instance.air_gap_qa_bastion.network_interface.0.access_config.0.nat_ip}"
      type     = "ssh"
      user     = "bastion"
      private_key = file("~/.ssh/id_rsa")
    }
  }
}

# # -----------------------------------------------
# # NFS
# # -----------------------------------------------
# resource "google_compute_instance" "air_gap_qa_nfs" {
#   name         = "air-gap-qa-${random_pet.cluster.id}-nfs"
#   machine_type = "e2-medium"
  
#   metadata_startup_script = file("files/nfs_startup.sh")

#   tags = ["${random_pet.cluster.id}-nfs"]
  
#   scheduling {
#     preemptible = true
#     automatic_restart = false
#     provisioning_model = "SPOT"
#   }
  
#   boot_disk {
#     initialize_params {
#       size  = 150
#       image = "centos-7-v20221004"
#     }
#   }

#   network_interface {
#     subnetwork = google_compute_subnetwork.public_subnet.name
#   }
# }

# -----------------------------------------------
# K3S MASTER NODE TEMPLATE
# -----------------------------------------------
resource "google_compute_instance_template" "air_gap_qa_master_node_template" {
  name         = "air-gap-qa-master-node-${random_pet.cluster.id}"
  machine_type = var.master_node_type

  metadata_startup_script = file("files/master_nodes_pre_setup.sh")

  scheduling {
    preemptible = false
    automatic_restart = false
    #provisioning_model = "SPOT"
    on_host_maintenance = "TERMINATE"
  }
  
  disk {
    source_image = var.vm_image
    auto_delete  = true
    disk_size_gb = 500
    boot         = true
  }

network_interface {
    subnetwork = google_compute_subnetwork.private_subnet.name
  }
}

# -----------------------------------------------
# K3S WORKER NODE TEMPLATE
# -----------------------------------------------
resource "google_compute_instance_template" "air_gap_qa_worker_node_template" {
  name         = "air-gap-qa-worker-node-${random_pet.cluster.id}"
  machine_type = var.worker_node_type

  metadata_startup_script = file("files/worker_nodes_pre_setup.sh")

  scheduling {
    preemptible = false
    automatic_restart = false
    #provisioning_model = "SPOT"
    on_host_maintenance = "TERMINATE"
  }
  
  disk {
    source_image = var.vm_image
    auto_delete  = true
    disk_size_gb = 500
    boot         = true
  }

  network_interface {
    subnetwork = google_compute_subnetwork.private_subnet.name
  }
}

# -----------------------------------------------
# K3S GPU NODE TEMPLATE
# -----------------------------------------------
resource "google_compute_instance_template" "air_gap_qa_gpu_node_template" {
  name         = "air-gap-qa-gpu-node-${random_pet.cluster.id}"
  machine_type = var.gpu_node_type

  metadata_startup_script = file("files/gpu_nodes_pre_setup.sh")

  # scheduling {
  #   preemptible = false
  #   automatic_restart = false
  # }
  scheduling {
    preemptible = false
    automatic_restart = false
    #provisioning_model = "SPOT"
    on_host_maintenance = "TERMINATE"
  }
  
  disk {
    source_image = var.vm_image
    auto_delete  = true
    disk_size_gb = 1000
    boot         = true
  }

  guest_accelerator {
    type = "nvidia-tesla-t4"
    count = 1
  }

  network_interface {
    subnetwork = google_compute_subnetwork.private_subnet.name
  }
}

# -----------------------------------------------
# MASTERS
# -----------------------------------------------
resource "google_compute_instance_from_template" "master" {
  count                    = var.master_node_count
  name                     = format("%s%d", "air-gap-qa-${random_pet.cluster.id}-master", count.index + 1)
  source_instance_template = google_compute_instance_template.air_gap_qa_master_node_template.id
}

# -----------------------------------------------
# WORKERS
# -----------------------------------------------
resource "google_compute_instance_from_template" "worker" {
  count                    = var.worker_node_count
  name                     = format("%s%d", "air-gap-qa-${random_pet.cluster.id}-worker", count.index + 1)
  source_instance_template = google_compute_instance_template.air_gap_qa_worker_node_template.id
}

# -----------------------------------------------
# GPU
# -----------------------------------------------
resource "google_compute_instance_from_template" "gpu" {
  count                    = var.gpu_node_count
  name                     = format("%s%d", "air-gap-qa-${random_pet.cluster.id}-gpu", count.index + 1)
  source_instance_template = google_compute_instance_template.air_gap_qa_gpu_node_template.id
}

resource "null_resource" "exec" {
  provisioner "local-exec" {
    command = "sed -r -i 's/air-gap-qa-[a-z]*-[a-z]*/air-gap-qa-${random_pet.cluster.id}/g' config/inventory.ini ../ssh_add_keys_to_nodes.sh ../nginx.sh ../install_nfs_common.sh ../copy_kubeconfig.sh"
  }
}

resource "null_resource" tools {
  provisioner "file" {
    source      = "config"
    destination = "config"
  }

  provisioner "file" {
    source      = "../copy_kubeconfig.sh"
    destination = "copy_kubeconfig.sh"
  }

  provisioner "file" {
    source      = "../ssh_add_keys_to_nodes.sh"
    destination = "ssh_add_keys_to_nodes.sh"
  }

  provisioner "file" {
    source      = "../install_configure_gsutils.sh"
    destination = "install_configure_gsutils.sh"
  }

  provisioner "file" {
    source      = "../install_nfs_common.sh"
    destination = "install_nfs_common.sh"
  }

  provisioner "file" {
    source      = "../nginx.sh"
    destination = "nginx.sh"
  }

  connection {
    host     = "${google_compute_instance.air_gap_qa_bastion.network_interface.0.access_config.0.nat_ip}"
    type     = "ssh"
    user     = "bastion"
    private_key = file("~/.ssh/id_rsa")
  }
}

resource "null_resource" clean-up {
  provisioner "remote-exec" {
    inline = [
      "cd config",
      "cp config/* .",
      "rm -rdf config",
      "mv ../ansible.cfg ansible.cfg"
    ]
  
    connection {
      host     = "${google_compute_instance.air_gap_qa_bastion.network_interface.0.access_config.0.nat_ip}"
      type     = "ssh"
      user     = "bastion"
      private_key = file("~/.ssh/id_rsa")
    }
  }
}
