# Configuration des VMs à créer
locals {
  vms = {
    web01 = {
      name        = "web01"
      description = "Web server 01"
      cores       = 2
      memory      = 2048
      ip          = "192.168.1.101"
      mac         = "BC:24:11:44:BF:01"
      tags        = ["terraform", "web", "debian"]
      groups      = ["webservers"]
    }
    web02 = {
      name        = "web02"
      description = "Web server 02"
      cores       = 2
      memory      = 2048
      ip          = "192.168.1.102"
      mac         = "BC:24:11:44:BF:02"
      tags        = ["terraform", "web", "debian"]
      groups      = ["webservers"]
    }
    db01 = {
      name        = "db01"
      description = "Database server"
      cores       = 4
      memory      = 4096
      ip          = "192.168.1.110"
      mac         = "BC:24:11:44:BF:10"
      tags        = ["terraform", "database", "debian"]
      groups      = ["databases"]
    }
  }
}

# Créer les VMs en boucle
resource "proxmox_virtual_environment_vm" "vms" {
  for_each = local.vms

  depends_on = [
    proxmox_virtual_environment_file.user_config,
    proxmox_virtual_environment_file.vendor_config
  ]

  name        = each.value.name
  description = each.value.description
  tags        = each.value.tags
  node_name   = var.pve_node

  cpu {
    cores = each.value.cores
  }

  memory {
    dedicated = each.value.memory
    floating  = each.value.memory
  }

  disk {
    datastore_id = "local-lvm"
    file_id      = proxmox_virtual_environment_download_file.debian_12.id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    ssd          = true
  }

  network_device {
    bridge      = "vmbr0"
    model       = "virtio"
    mac_address = each.value.mac
  }

  operating_system {
    type = "l26"
  }

  agent {
    enabled = true
  }

  initialization {
    ip_config {
      ipv4 {
        address = "${each.value.ip}/24"
        gateway = "192.168.1.1"
      }
    }
    user_data_file_id   = proxmox_virtual_environment_file.user_config.id
    vendor_data_file_id = proxmox_virtual_environment_file.vendor_config.id
  }
}
