# Configuration des VMs VMware depuis CSV
# Ce fichier lit directement le fichier vms-vmware.csv

locals {
  # Charger le CSV VMware et le parser
  vmware_vms_csv_raw = csvdecode(file("../config/vms-vmware.csv"))

  # Filtrer les lignes commentées (commençant par #)
  vmware_vms_csv = [
    for vm in local.vmware_vms_csv_raw :
    vm if !startswith(vm.name, "#")
  ]

  # Transformer en map pour utilisation avec for_each
  vmware_vms = {
    for vm in local.vmware_vms_csv :
    replace(vm.name, "-", "_") => {
      vmid          = tonumber(vm.vmid)
      name          = vm.name
      description   = vm.description
      datacenter    = vm.datacenter
      cluster       = vm.cluster
      datastore     = vm.datastore
      environment   = vm.environment
      cores         = tonumber(vm.cores)
      memory        = tonumber(vm.memory)
      disk_size     = tonumber(vm.disk_size)
      ip            = vm.ip
      gateway       = vm.gateway
      mac           = vm.mac
      tags          = split(",", vm.tags)
      groups        = split(",", vm.ansible_groups)
      playbooks     = vm.playbooks
      playbook_vars = vm.playbook_vars
    }
  }
}

# Note: Les ressources VMware seront créées ici quand vous aurez des VMs VMware
# Pour l'instant, le CSV est vide (ligne commentée), donc aucune ressource ne sera créée

# Exemple de ressource VMware (décommenter quand vous aurez des VMs):
# resource "vsphere_virtual_machine" "vmware_vms" {
#   for_each = local.vmware_vms
#   
#   name             = each.value.name
#   resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
#   datastore_id     = data.vsphere_datastore.datastore.id
#   
#   num_cpus = each.value.cores
#   memory   = each.value.memory
#   
#   # ... reste de la configuration VMware
# }

# Générer l'inventaire Ansible pour VMware
resource "local_file" "ansible_inventory_vmware" {
  filename = "../ansible/inventory/vmware/inventory.ini"
  content = templatefile("${path.module}/templates/inventory.tpl", {
    vms = local.vmware_vms
  })

  # Ne créer le fichier que si on a des VMs VMware
  count = length(local.vmware_vms) > 0 ? 1 : 0
}

output "vmware_vms_count" {
  description = "Nombre de VMs VMware configurées"
  value       = length(local.vmware_vms)
}
