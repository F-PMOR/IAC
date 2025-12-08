# Inventaire Ansible global - Toutes infrastructures
# Généré automatiquement par Terraform
# Ne pas modifier manuellement - ce fichier sera écrasé

# ===========================================
# VMs PROXMOX
# ===========================================
%{ if length(proxmox_vms) > 0 ~}
%{ for group in distinct(flatten([for vm in proxmox_vms : vm.groups])) ~}
[proxmox_${group}]
%{ for key, vm in proxmox_vms ~}
%{ if contains(vm.groups, group) ~}
${vm.name} ansible_host=${vm.ip} ansible_user=ansible ansible_ssh_private_key_file=~/.ssh/id_ecdsa provider=proxmox
%{ endif ~}
%{ endfor ~}

%{ endfor ~}
%{ else ~}
# Aucune VM Proxmox configurée

%{ endif ~}
# ===========================================
# VMs VMWARE
# ===========================================
%{ if length(vmware_vms) > 0 ~}
%{ for group in distinct(flatten([for vm in vmware_vms : vm.groups])) ~}
[vmware_${group}]
%{ for key, vm in vmware_vms ~}
%{ if contains(vm.groups, group) ~}
${vm.name} ansible_host=${vm.ip} ansible_user=ansible ansible_ssh_private_key_file=~/.ssh/id_ecdsa provider=vmware
%{ endif ~}
%{ endfor ~}

%{ endfor ~}
%{ else ~}
# Aucune VM VMware configurée

%{ endif ~}
# ===========================================
# GROUPES GLOBAUX (tous providers)
# ===========================================
%{ for group in all_groups ~}
[${group}:children]
%{ if length(proxmox_vms) > 0 ~}
proxmox_${group}
%{ endif ~}
%{ if length(vmware_vms) > 0 ~}
vmware_${group}
%{ endif ~}

%{ endfor ~}
# ===========================================
# GROUPES PAR PROVIDER
# ===========================================
%{ if length(proxmox_vms) > 0 ~}
[proxmox:children]
%{ for group in distinct(flatten([for vm in proxmox_vms : vm.groups])) ~}
proxmox_${group}
%{ endfor ~}

%{ endif ~}
%{ if length(vmware_vms) > 0 ~}
[vmware:children]
%{ for group in distinct(flatten([for vm in vmware_vms : vm.groups])) ~}
vmware_${group}
%{ endfor ~}

%{ endif ~}
# ===========================================
# GROUPE ALL
# ===========================================
[all:children]
%{ if length(proxmox_vms) > 0 ~}
proxmox
%{ endif ~}
%{ if length(vmware_vms) > 0 ~}
vmware
%{ endif ~}

[all:vars]
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
