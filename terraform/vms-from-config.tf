# Terraform configuration generated from vms-config.yml
# DO NOT EDIT MANUALLY - This file is auto-generated
# Pour utiliser cette configuration, commentez ou renommez le fichier vms.tf existant

# Configuration des VMs depuis CSV
locals {
  vms_from_csv = {
    dolibarr_prod01 = {
      name        = "dolibarr-prod01"
      description = "Dolibarr Production - Serveur principal"
      node        = "pve01"
      cores       = 2
      memory      = 4096
      disk_size   = 50
      ip          = "192.168.1.101"
      gateway     = "192.168.1.1"
      mac         = "BC:24:11:44:BF:01"
      tags        = ["terraform", "prod", "web", "erp", "debian"]
      groups      = ["prod", "webservers", "dolibarr"]
    }
    dolibarr_preprod01 = {
      name        = "dolibarr-preprod01"
      description = "Dolibarr Pre-Production - Tests"
      node        = "pve01"
      cores       = 2
      memory      = 2048
      disk_size   = 30
      ip          = "192.168.1.111"
      gateway     = "192.168.1.1"
      mac         = "BC:24:11:44:BF:11"
      tags        = ["terraform", "preprod", "web", "erp", "debian"]
      groups      = ["preprod", "webservers", "dolibarr"]
    }
    dolibarr_dev01 = {
      name        = "dolibarr-dev01"
      description = "Dolibarr Développement"
      node        = "pve02"
      cores       = 2
      memory      = 2048
      disk_size   = 30
      ip          = "192.168.1.121"
      gateway     = "192.168.1.1"
      mac         = "BC:24:11:44:BF:21"
      tags        = ["terraform", "dev", "web", "debian"]
      groups      = ["dev", "webservers", "dolibarr"]
    }
    mysql_prod01 = {
      name        = "mysql-prod01"
      description = "MySQL/MariaDB Production"
      node        = "pve01"
      cores       = 4
      memory      = 8192
      disk_size   = 100
      ip          = "192.168.1.100"
      gateway     = "192.168.1.1"
      mac         = "BC:24:11:44:BF:10"
      tags        = ["terraform", "prod", "database", "debian"]
      groups      = ["prod", "databases"]
    }
  }
  
  # Liste des nodes uniques utilisés
  unique_nodes = toset(["pve01", "pve01", "pve02", "pve01"])
}

# Télécharger l'image Debian sur chaque node utilisé
resource "proxmox_virtual_environment_download_file" "debian_12_csv" {
  for_each = local.unique_nodes
  
  content_type          = "iso"
  datastore_id          = "local"
  file_name             = "debian-12-generic-amd64.img"
  node_name             = each.value
  url                   = var.debian_image_url
  checksum              = var.debian_image_checksum
  checksum_algorithm    = var.debian_image_checksum_algorithm
  overwrite             = false
  overwrite_unmanaged   = true
}

# Créer les fichiers cloud-init sur chaque node
resource "proxmox_virtual_environment_file" "user_config_csv" {
  for_each = local.unique_nodes
  
  content_type  = "snippets"
  datastore_id  = "local"
  node_name     = each.value

  source_raw {
    data        = file("cloudinit/user-config.yaml")
    file_name   = "user-config.yaml"
  }
}

resource "proxmox_virtual_environment_file" "vendor_config_csv" {
  for_each = local.unique_nodes
  
  content_type  = "snippets"
  datastore_id  = "local"
  node_name     = each.value

  source_raw {
    data        = file("cloudinit/vendor-config.yaml")
    file_name   = "vendor-config.yaml"
  }
}

# Créer les VMs en boucle
resource "proxmox_virtual_environment_vm" "vms_csv" {
  for_each = local.vms_from_csv

  depends_on = [
    proxmox_virtual_environment_file.user_config_csv,
    proxmox_virtual_environment_file.vendor_config_csv,
    proxmox_virtual_environment_download_file.debian_12_csv
  ]

  name        = each.value.name
  description = each.value.description
  tags        = each.value.tags
  node_name   = each.value.node

  cpu {
    cores = each.value.cores
  }

  memory {
    dedicated = each.value.memory
    floating  = each.value.memory
  }

  disk {
    datastore_id = "local-lvm"
    file_id      = proxmox_virtual_environment_download_file.debian_12_csv[each.value.node].id
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
        gateway = each.value.gateway
      }
    }
    user_data_file_id   = proxmox_virtual_environment_file.user_config_csv[each.value.node].id
    vendor_data_file_id = proxmox_virtual_environment_file.vendor_config_csv[each.value.node].id
  }
}

# Génération automatique de l'inventaire Ansible pour les VMs CSV
resource "local_file" "ansible_inventory_csv" {
  content = templatefile("${path.module}/templates/inventory.tpl", {
    vms = {
      for key, vm in proxmox_virtual_environment_vm.vms_csv : key => {
        name   = vm.name
        ip     = split("/", vm.initialization[0].ip_config[0].ipv4[0].address)[0]
        groups = local.vms_from_csv[key].groups
      }
    }
  })
  filename        = "${path.module}/../ansible/inventory/proxmox/inventory.ini"
  file_permission = "0644"
}

# Output pour afficher les IPs des VMs CSV
output "vms_csv_info" {
  value = {
    for key, vm in proxmox_virtual_environment_vm.vms_csv : key => {
      name = vm.name
      ip   = split("/", vm.initialization[0].ip_config[0].ipv4[0].address)[0]
      id   = vm.id
    }
  }
  description = "Information des VMs créées depuis CSV"
}
