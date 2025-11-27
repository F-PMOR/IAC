resource "proxmox_virtual_environment_download_file" "debian_12" {
  content_type          = "iso"
  datastore_id          = "local"
  file_name             = "debian-12-generic-amd64.img"
  node_name             = var.pve_node
  url                   = var.debian_image_url
  checksum              = var.debian_image_checksum
  checksum_algorithm    = var.debian_image_checksum_algorithm
  overwrite             = true
  overwrite_unmanaged   = true
}

resource "proxmox_virtual_environment_file" "user_config" {
  content_type  = "snippets"
  datastore_id  = "local"
  node_name     = var.pve_node

  source_raw {
    data        = file("cloudinit/user-config.yaml")
    file_name   = "user-config.yaml"
  }
}

resource "proxmox_virtual_environment_file" "vendor_config" {
  content_type  = "snippets"
  datastore_id  = "local"
  node_name     = var.pve_node

  source_raw {
    data        = file("cloudinit/vendor-config.yaml")
    file_name   = "vendor-config.yaml"
  }
}

# Les VMs sont maintenant définies dans vms.tf

