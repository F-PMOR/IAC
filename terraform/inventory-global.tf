# Inventaire Ansible global - Toutes les infrastructures
# Génère un inventaire combiné Proxmox + VMware

locals {
  # Combiner toutes les VMs de tous les providers
  all_vms = merge(
    local.proxmox_vms,
    local.vmware_vms
  )

  # Extraire tous les groupes uniques
  all_groups = distinct(flatten([
    for vm_key, vm in local.all_vms : vm.groups
  ]))
}

# Générer l'inventaire global (tous les providers)
resource "local_file" "ansible_inventory_global" {
  filename = "../ansible/inventory/all/inventory.ini"
  content = templatefile("${path.module}/templates/inventory-global.tpl", {
    proxmox_vms = local.proxmox_vms
    vmware_vms  = local.vmware_vms
    all_groups  = local.all_groups
  })
}

# Output pour diagnostic
output "infrastructure_summary" {
  description = "Résumé de l'infrastructure"
  value = {
    proxmox_vms = length(local.proxmox_vms)
    vmware_vms  = length(local.vmware_vms)
    total_vms   = length(local.all_vms)
    groups      = local.all_groups
  }
}
