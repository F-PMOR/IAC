# Configuration pour ignorer les modifications sur les VMs existantes
# Utilisé pour éviter que Terraform ne veuille recréer les VMs déjà déployées manuellement

# Cette approche permet de:
# 1. Garder les VMs existantes telles quelles
# 2. Laisser Terraform créer seulement les nouvelles VMs
# 3. Éviter les imports complexes qui peuvent bloquer

# Pour marquer une VM comme "existante" (à ne pas toucher):
# Ajoutez un tag "managed=manual" dans Proxmox
# Ou utilisez les blocks moved ci-dessous pour chaque VM

# Exemple pour ignorer une VM spécifique:
# resource "proxmox_virtual_environment_vm" "existing_vm" {
#   lifecycle {
#     ignore_changes = all
#   }
# }

# Alternative: utiliser des imports manuels dans le state sans effectuer de changements
# terraform state rm 'proxmox_virtual_environment_vm.vms_csv["vm_name"]'
# terraform import 'proxmox_virtual_environment_vm.vms_csv["vm_name"]' node/vmid

