# Inventaire Ansible généré automatiquement par Terraform
# Ne pas modifier manuellement - ce fichier sera écrasé

# Groupes par type de serveur
%{ for group in distinct(flatten([for vm in vms : vm.groups])) ~}
[${group}]
%{ for key, vm in vms ~}
%{ if contains(vm.groups, group) ~}
${vm.name} ansible_host=${vm.ip} ansible_user=ansible ansible_ssh_private_key_file=~/.ssh/id_ecdsa
%{ endif ~}
%{ endfor ~}

%{ endfor ~}
# Groupe global
[all:children]
%{ for group in distinct(flatten([for vm in vms : vm.groups])) ~}
${group}
%{ endfor ~}

[all:vars]
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
