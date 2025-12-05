# Configuration des VMs Proxmox depuis CSV
# Ce fichier lit directement le fichier vms-proxmox.csv

locals {
  # Charger le CSV Proxmox et le parser
  proxmox_vms_csv = csvdecode(file("../config/vms-proxmox.csv"))

  # Transformer en map pour utilisation avec for_each
  proxmox_vms = {
    for vm in local.proxmox_vms_csv :
    replace(vm.name, "-", "_") => {
      vmid                  = tonumber(vm.vmid)
      name                  = vm.name
      description           = vm.description
      node                  = vm.node
      environment           = vm.environment
      cores                 = tonumber(vm.cores)
      memory                = tonumber(vm.memory)
      disk_size             = tonumber(vm.disk_size)
      ip                    = vm.ip
      gateway               = vm.gateway
      mac                   = vm.mac
      tags                  = split(",", vm.tags)
      groups                = split(",", vm.ansible_groups)
      playbooks             = vm.playbooks
      playbook_vars         = vm.playbook_vars
      db_backup_file        = vm.db_backup_file
      documents_backup_file = vm.documents_backup_file
      dolibarr_domain       = vm.dolibarr_domain
      git_repo_url          = vm.git_repo_url
      git_branch            = vm.git_branch
    }
  }

  # Liste des nodes uniques
  proxmox_nodes = toset([for vm in local.proxmox_vms : vm.node])
}

# Télécharger l'image Debian sur chaque node utilisé
resource "proxmox_virtual_environment_download_file" "debian_12_proxmox" {
  for_each = local.proxmox_nodes

  content_type        = "iso"
  datastore_id        = "local"
  file_name           = "debian-12-generic-amd64.img"
  node_name           = each.key
  url                 = var.debian_image_url
  checksum            = var.debian_image_checksum
  checksum_algorithm  = var.debian_image_checksum_algorithm
  overwrite           = true
  overwrite_unmanaged = true
}

# Créer le fichier user-config sur chaque node
resource "proxmox_virtual_environment_file" "user_config_proxmox" {
  for_each = local.proxmox_nodes

  content_type = "snippets"
  datastore_id = "local"
  node_name    = each.key

  source_raw {
    data      = file("cloudinit/user-config.yaml")
    file_name = "user-config.yaml"
  }
}

# Créer le fichier vendor-config Proxmox sur chaque node
resource "proxmox_virtual_environment_file" "vendor_config_proxmox" {
  for_each = local.proxmox_nodes

  content_type = "snippets"
  datastore_id = "local"
  node_name    = each.key

  source_raw {
    data      = file("cloudinit/vendor-config-proxmox.yaml")
    file_name = "vendor-config-proxmox.yaml"
  }
}

# Créer les VMs Proxmox
resource "proxmox_virtual_environment_vm" "proxmox_vms" {
  for_each = local.proxmox_vms

  name        = each.value.name
  description = each.value.description
  tags        = each.value.tags
  node_name   = each.value.node
  vm_id       = each.value.vmid

  # Configuration matérielle
  cpu {
    cores = each.value.cores
    type  = "host"
  }

  memory {
    dedicated = each.value.memory
  }

  # Agent QEMU
  agent {
    enabled = true
    timeout = "30s"
  }

  # Disque système
  disk {
    datastore_id = "local-lvm"
    file_id      = proxmox_virtual_environment_download_file.debian_12_proxmox[each.value.node].id
    interface    = "scsi0"
    size         = each.value.disk_size
    iothread     = true
    discard      = "on"
  }

  # Interface réseau
  network_device {
    bridge      = "vmbr0"
    mac_address = each.value.mac
  }

  # Configuration cloud-init
  initialization {
    ip_config {
      ipv4 {
        address = "${each.value.ip}/24"
        gateway = each.value.gateway
      }
    }

    user_data_file_id   = proxmox_virtual_environment_file.user_config_proxmox[each.value.node].id
    vendor_data_file_id = proxmox_virtual_environment_file.vendor_config_proxmox[each.value.node].id
  }

  # Démarrage automatique
  startup {
    order = each.value.vmid - 199 # mysql=1, dolibarr-prod=2, etc.
  }

  # Ne pas détruire les VMs par accident et ignorer les changements sur les disques/cloud-init existants
  lifecycle {
    prevent_destroy = false # Mettre à true en production
    ignore_changes = [
      disk,                    # Ignorer les changements de disque (VMs existantes)
      initialization,          # Ignorer cloud-init (déjà configuré)
      network_device,          # Ignorer réseau (déjà configuré)
    ]
  }

  # Dépendances
  depends_on = [
    proxmox_virtual_environment_download_file.debian_12_proxmox,
    proxmox_virtual_environment_file.user_config_proxmox,
    proxmox_virtual_environment_file.vendor_config_proxmox
  ]
}

# Générer l'inventaire Ansible
resource "local_file" "ansible_inventory_proxmox" {
  filename = "../ansible/inventory/proxmox/inventory.ini"
  content = templatefile("${path.module}/templates/inventory.tpl", {
    vms = local.proxmox_vms
  })
}
