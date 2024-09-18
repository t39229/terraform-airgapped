output "bastion_public_ip_addr" {
 value = google_compute_instance.air_gap_qa_bastion.network_interface.0.access_config.0.nat_ip
}
