# Input variable definitions


variable "master_node_type" {
 description = "Type of the VM for master nodes"
 type        = string
 default     = "n1-standard-8"
}


variable "master_node_count" {
 description = "Number of master nodes"
 type        = number
 default     = 0
}


variable "gpu_node_type" {
 description = "Type of the VM for gpu nodes"
 type        = string
 default     = "n1-standard-32"
}


variable "gpu_node_count" {
 description = "Number of gpu nodes"
 type        = number
 default     = 1
}


variable "worker_node_type" {
 description = "Type of the VM"
 type        = string
 default     = "n2d-standard-8"
}
variable "worker_node_count" {
 description = "Number of worker nodes"
 type        = number
 default     = 0
}


variable "vm_image" {
 description = "Name of the VM image"
 type        = string
 default     = "ubuntu-2204-jammy-v20230714"
}


variable "region" {
 description = "Name of the Region"
 type        = string
 default     = "europe-west4"
}

