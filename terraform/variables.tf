variable "pve_insecure" {
  type        = bool
  description = "Enable insecure connexion"
  default     = true
}

variable "pve_endpoint" {
  type        = string
  description = "API endpoint URL"
  default     = "" # Sera lu depuis PROXMOX_VE_ENDPOINT si non fourni
}

variable "pve_password" {
  type        = string
  description = "Password"
  sensitive   = true
  default     = "" # Sera lu depuis PROXMOX_VE_PASSWORD si non fourni
}

variable "pve_username" {
  type        = string
  description = "Username"
  default     = "" # Sera lu depuis PROXMOX_VE_USERNAME si non fourni
}
variable "pve_node" {
  type        = string
  description = "Node where install elements"
  default     = ""
}
variable "debian_image_url" {
  type        = string
  description = "The URL for the latest Debian 12 Bookworm qcow2 image"
  default     = ""
}
variable "debian_image_checksum_algorithm" {
  type        = string
  description = "Checksum algo used by image"
  default     = "sha512"
}

variable "debian_image_checksum" {
  type        = string
  description = "SHA Digest of the image"
  default     = ""
}

# ========================================
# VMware vSphere Variables
# ========================================

variable "vsphere_server" {
  type        = string
  description = "vSphere server address"
  sensitive   = true
  default     = "" # Sera lu depuis VSPHERE_SERVER si non fourni
}

variable "vsphere_user" {
  type        = string
  description = "vSphere username"
  sensitive   = true
  default     = "" # Sera lu depuis VSPHERE_USER si non fourni
}

variable "vsphere_password" {
  type        = string
  description = "vSphere password"
  sensitive   = true
  default     = "" # Sera lu depuis VSPHERE_PASSWORD si non fourni
}

variable "vsphere_allow_unverified_ssl" {
  type        = bool
  description = "Allow unverified SSL certificates"
  default     = true
}

variable "vsphere_datacenter" {
  type        = string
  description = "vSphere datacenter name"
  default     = ""
}

variable "vsphere_datastore" {
  type        = string
  description = "vSphere datastore name"
  default     = ""
}

variable "vsphere_network" {
  type        = string
  description = "vSphere network name"
  default     = "VM Network"
}

variable "vsphere_template" {
  type        = string
  description = "vSphere VM template name"
  default     = ""
}

# ========================================
# Cloud-init Configuration
# ========================================

variable "cloud_init_root_password" {
  type        = string
  description = "Root password for cloud-init (plain text, will be hashed by cloud-init)"
  sensitive   = true
  default     = "root" # Sera lu depuis TF_VAR_cloud_init_root_password si non fourni
}

variable "cloud_init_ansible_password" {
  type        = string
  description = "Ansible user password for cloud-init (plain text, will be hashed by cloud-init)"
  sensitive   = true
  default     = "ansible" # Sera lu depuis TF_VAR_cloud_init_ansible_password si non fourni
}
