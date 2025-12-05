# Flux de génération des inventaires Ansible

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          SOURCES (CSV)                                  │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  config/vms-proxmox.csv          config/vms-vmware.csv                 │
│  ┌───────────────────┐           ┌───────────────────┐                 │
│  │ mysql-prod01      │           │ app-prod01        │                 │
│  │ dolibarr-prod01   │           │ web-prod01        │                 │
│  │ dolibarr-preprod  │           │ # (commenté)      │                 │
│  │ dolibarr-dev01    │           └───────────────────┘                 │
│  └───────────────────┘                                                  │
│                                                                         │
└───────────────┬─────────────────────────────────┬───────────────────────┘
                │                                 │
                │ csvdecode()                     │ csvdecode()
                │                                 │
                ▼                                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                   TERRAFORM LOCALS                                      │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  local.proxmox_vms = {           local.vmware_vms = {                  │
│    mysql_prod01 = {...}            app_prod01 = {...}                  │
│    dolibarr_prod01 = {...}         web_prod01 = {...}                  │
│    ...                             ...                                  │
│  }                                }                                     │
│                                                                         │
└───────────┬─────────────┬───────────────────┬─────────────────────────┘
            │             │                   │
            │             │                   │
            ▼             ▼                   ▼
┌──────────────┐ ┌──────────────┐  ┌───────────────────┐
│   TEMPLATE   │ │   TEMPLATE   │  │     TEMPLATE      │
│ inventory.tpl│ │ inventory.tpl│  │inventory-global   │
│              │ │              │  │      .tpl         │
└──────┬───────┘ └──────┬───────┘  └─────────┬─────────┘
       │                │                    │
       │ templatefile() │ templatefile()     │ templatefile()
       │                │                    │
       ▼                ▼                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│              INVENTAIRES ANSIBLE GÉNÉRÉS                               │
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│  inventory/proxmox/     inventory/vmware/     inventory/all/          │
│  inventory.ini          inventory.ini         inventory.ini           │
│  ┌──────────────┐       ┌──────────────┐      ┌──────────────────┐   │
│  │ [prod]       │       │ [prod]       │      │ [proxmox_prod]   │   │
│  │ mysql-prod01 │       │ app-prod01   │      │ mysql-prod01     │   │
│  │ dolibarr-... │       │              │      │ dolibarr-...     │   │
│  │              │       │ [app]        │      │                  │   │
│  │ [databases]  │       │ app-prod01   │      │ [vmware_prod]    │   │
│  │ mysql-prod01 │       │ web-prod01   │      │ app-prod01       │   │
│  │              │       │              │      │                  │   │
│  │ [all:children]      │ [all:children]      │ [prod:children]  │   │
│  │ prod         │       │ prod         │      │ proxmox_prod     │   │
│  │ databases    │       │ app          │      │ vmware_prod      │   │
│  │ ...          │       │ ...          │      │                  │   │
│  └──────────────┘       └──────────────┘      │ [all:children]   │   │
│                                               │ proxmox          │   │
│                                               │ vmware           │   │
│                                               └──────────────────┘   │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘
                               │
                               │ Utilisé par
                               ▼
┌────────────────────────────────────────────────────────────────────────┐
│                    ANSIBLE PLAYBOOKS                                   │
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│  # Cibler Proxmox uniquement                                          │
│  ansible-playbook -i inventory/proxmox/inventory.ini orchestrate.yml  │
│                                                                        │
│  # Cibler VMware uniquement                                           │
│  ansible-playbook -i inventory/vmware/inventory.ini orchestrate.yml   │
│                                                                        │
│  # Cibler tous les providers                                          │
│  ansible-playbook -i inventory/all/inventory.ini orchestrate.yml      │
│                                                                        │
│  # Cibler un environnement spécifique tous providers                  │
│  ansible-playbook -i inventory/all/inventory.ini orchestrate.yml \    │
│                   --limit prod                                         │
│                                                                        │
│  # Cibler un provider + environnement                                 │
│  ansible-playbook -i inventory/all/inventory.ini orchestrate.yml \    │
│                   --limit proxmox_prod                                 │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘
```

## Résumé du flux

1. **CSV** : Vous créez/modifiez les VMs dans les fichiers CSV
2. **Terraform** : Lit les CSV avec `csvdecode()` et crée des `locals`
3. **Templates** : Terraform applique les templates Jinja2 sur les locals
4. **Inventaires** : Les fichiers `.ini` sont générés automatiquement
5. **Ansible** : Utilise les inventaires pour cibler les VMs

## Avantages de cette architecture

✅ **Source unique de vérité** : Les CSV définissent tout  
✅ **Génération automatique** : Pas de maintenance manuelle des inventaires  
✅ **Multi-provider** : Proxmox et VMware gérés séparément ou ensemble  
✅ **Flexibilité** : 3 inventaires pour différents cas d'usage  
✅ **Cohérence** : Terraform garantit que les inventaires reflètent les CSV  
✅ **Groupes dynamiques** : Ajoutez un groupe dans le CSV, il apparaît dans l'inventaire
