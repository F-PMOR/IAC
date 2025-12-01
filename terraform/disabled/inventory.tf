# Génération automatique de l'inventaire Ansible
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/templates/inventory.tpl", {
    vms = {
      for key, vm in proxmox_virtual_environment_vm.vms : key => {
        name   = vm.name
        ip     = split("/", vm.initialization[0].ip_config[0].ipv4[0].address)[0]
        groups = local.vms[key].groups
      }
    }
  })
  filename        = "${path.module}/../ansible/inventory/proxmox/inventory.ini"
  file_permission = "0644"
}

# Output pour afficher les IPs
output "vms_info" {
  value = {
    for key, vm in proxmox_virtual_environment_vm.vms : key => {
      name = vm.name
      ip   = split("/", vm.initialization[0].ip_config[0].ipv4[0].address)[0]
      id   = vm.id
    }
  }
  description = "Information des VMs créées"
}
