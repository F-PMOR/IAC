# Inventaires Ansible

Ce dossier contient les inventaires Ansible générés automatiquement par Terraform.

## 📁 Structure

```
inventory/
├── proxmox/
│   └── inventory.ini       # VMs Proxmox uniquement
├── vmware/
│   └── inventory.ini       # VMs VMware uniquement
└── all/
    └── inventory.ini       # Toutes les VMs (Proxmox + VMware)
```

## 🔄 Génération automatique

Ces fichiers sont **générés automatiquement** par Terraform lors du `tofu apply` :

```bash
cd terraform/
tofu apply

# Génère :
# - ansible/inventory/proxmox/inventory.ini  (depuis vms-proxmox.tf)
# - ansible/inventory/vmware/inventory.ini   (depuis vms-vmware.tf)
# - ansible/inventory/all/inventory.ini      (depuis inventory-global.tf)
```

**⚠️ Ne modifiez pas ces fichiers manuellement** - vos changements seront écrasés !

## 🎯 Utilisation

### Cibler uniquement Proxmox

```bash
ansible-playbook -i inventory/proxmox/inventory.ini playbooks/orchestrate.yml
./scripts/deploy-ansible.sh  # Utilise proxmox par défaut
```

### Cibler uniquement VMware

```bash
ansible-playbook -i inventory/vmware/inventory.ini playbooks/orchestrate.yml
# Ou modifier INVENTORY_FILE dans deploy-ansible.sh
```

### Cibler toutes les infrastructures

```bash
ansible-playbook -i inventory/all/inventory.ini playbooks/orchestrate.yml
```

## 📋 Structure des inventaires

### Inventaire Proxmox (`proxmox/inventory.ini`)

Groupes simples basés sur les colonnes CSV :

```ini
[prod]
mysql-prod01 ansible_host=192.168.1.100 ...
dolibarr-prod01 ansible_host=192.168.1.101 ...

[databases]
mysql-prod01 ansible_host=192.168.1.100 ...

[all:children]
prod
databases
...
```

### Inventaire VMware (`vmware/inventory.ini`)

Même structure que Proxmox, mais pour les VMs VMware.

### Inventaire Global (`all/inventory.ini`)

Combine les deux avec des préfixes pour éviter les conflits :

```ini
# Groupes par provider
[proxmox_prod]
mysql-prod01 ansible_host=192.168.1.100 ... provider=proxmox

[vmware_prod]
app-prod01 ansible_host=192.168.2.100 ... provider=vmware

# Groupes globaux (agrégation)
[prod:children]
proxmox_prod
vmware_prod

# Groupes par provider
[proxmox:children]
proxmox_prod
proxmox_databases
...

[vmware:children]
vmware_prod
vmware_app
...

[all:children]
proxmox
vmware
```

## 🔍 Exemples de filtrage

### Limiter à un provider

```bash
# Uniquement Proxmox
ansible all -i inventory/all/inventory.ini -m ping --limit proxmox

# Uniquement VMware
ansible all -i inventory/all/inventory.ini -m ping --limit vmware
```

### Limiter à un environnement

```bash
# Toutes les VMs prod (tous providers)
ansible prod -i inventory/all/inventory.ini -m ping

# Seulement les VMs prod Proxmox
ansible proxmox_prod -i inventory/all/inventory.ini -m ping

# Seulement les VMs prod VMware
ansible vmware_prod -i inventory/all/inventory.ini -m ping
```

### Combiner provider et groupe

```bash
# Bases de données Proxmox uniquement
ansible proxmox_databases -i inventory/all/inventory.ini -m ping

# Applications VMware uniquement
ansible vmware_app -i inventory/all/inventory.ini -m ping
```

## 🔧 Configuration des scripts

Mettre à jour `scripts/deploy-ansible.sh` pour choisir l'inventaire :

```bash
# Par défaut : Proxmox
INVENTORY_FILE="${INVENTORY_FILE:-${ANSIBLE_DIR}/inventory/proxmox/inventory.ini}"

# Pour utiliser VMware :
export INVENTORY_FILE=./ansible/inventory/vmware/inventory.ini
./scripts/deploy-ansible.sh

# Pour utiliser tous les providers :
export INVENTORY_FILE=./ansible/inventory/all/inventory.ini
./scripts/deploy-ansible.sh
```

## 🐛 Troubleshooting

### Inventaire vide ou manquant

**Cause :** Terraform n'a pas encore été appliqué ou le CSV est vide

**Solution :**
```bash
cd terraform/
tofu apply
```

### Groupes manquants

**Cause :** La colonne `ansible_groups` dans le CSV n'est pas correctement remplie

**Solution :** Vérifier le CSV et re-générer :
```bash
vim config/vms-proxmox.csv  # Vérifier la colonne ansible_groups
cd terraform/
tofu apply
```

### Conflits de noms entre Proxmox et VMware

**Cause :** Deux VMs ont le même nom dans différents providers

**Solution :** Dans l'inventaire global, les groupes sont préfixés (`proxmox_`, `vmware_`). Utiliser ces préfixes pour cibler spécifiquement :

```bash
ansible proxmox_web -i inventory/all/inventory.ini -m ping  # Web Proxmox
ansible vmware_web -i inventory/all/inventory.ini -m ping   # Web VMware
```

## 📚 Voir aussi

- `config/README-CSV-PROVIDERS.md` : Structure des CSV
- `terraform/templates/inventory.tpl` : Template d'inventaire par provider
- `terraform/templates/inventory-global.tpl` : Template d'inventaire global
- `terraform/inventory-global.tf` : Logique de génération de l'inventaire global
