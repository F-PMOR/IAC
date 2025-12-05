# Génération des Inventaires Ansible

## 🎯 Inventaires générés automatiquement

Terraform génère **3 inventaires** automatiquement lors du `tofu apply` :

### 1. Inventaire Proxmox
**Fichier :** `ansible/inventory/proxmox/inventory.ini`  
**Source :** `config/vms-proxmox.csv`  
**Généré par :** `terraform/vms-proxmox.tf`

Contient uniquement les VMs Proxmox avec leurs groupes.

### 2. Inventaire VMware
**Fichier :** `ansible/inventory/vmware/inventory.ini`  
**Source :** `config/vms-vmware.csv`  
**Généré par :** `terraform/vms-vmware.tf`

Contient uniquement les VMs VMware avec leurs groupes.

### 3. Inventaire Global
**Fichier :** `ansible/inventory/all/inventory.ini`  
**Source :** Les deux CSV combinés  
**Généré par :** `terraform/inventory-global.tf`

Contient toutes les VMs avec :
- Groupes préfixés par provider (`proxmox_prod`, `vmware_prod`)
- Groupes globaux agrégés (`prod`, `databases`, etc.)
- Variable `provider` sur chaque host

## 🔄 Comment ça fonctionne

### 1. Définir les VMs dans les CSV

**Proxmox :**
```csv
name,vmid,environment,node,description,cores,memory,disk_size,ip,gateway,mac,tags,ansible_groups,...
mysql-prod01,200,prod,pve01,MySQL Production,4,8192,100,192.168.1.100,192.168.1.1,BC:24:11:44:BF:10,"terraform,prod,database","prod,databases",...
```

**VMware :**
```csv
name,vmid,environment,datacenter,cluster,datastore,description,cores,memory,disk_size,ip,gateway,mac,tags,ansible_groups,...
app-prod01,1001,prod,DC1,Cluster1,datastore1,App Production,4,8192,100,192.168.2.100,192.168.2.1,00:50:56:XX:XX:XX,"terraform,prod,app","prod,appservers",...
```

### 2. Appliquer Terraform

```bash
cd terraform/
tofu apply
```

Terraform lit les CSV et génère les inventaires via :
- Template `templates/inventory.tpl` (pour Proxmox et VMware séparés)
- Template `templates/inventory-global.tpl` (pour l'inventaire global)

### 3. Utiliser avec Ansible

```bash
# Proxmox uniquement
ansible-playbook -i inventory/proxmox/inventory.ini playbooks/orchestrate.yml

# VMware uniquement
ansible-playbook -i inventory/vmware/inventory.ini playbooks/orchestrate.yml

# Toutes les infrastructures
ansible-playbook -i inventory/all/inventory.ini playbooks/orchestrate.yml
```

## 📋 Structure de l'inventaire global

L'inventaire global organise les VMs ainsi :

```ini
# Groupes spécifiques par provider
[proxmox_prod]
mysql-prod01 ansible_host=192.168.1.100 ... provider=proxmox

[vmware_prod]
app-prod01 ansible_host=192.168.2.100 ... provider=vmware

# Groupes globaux (agrégation)
[prod:children]
proxmox_prod
vmware_prod

# Groupes par provider (tous les groupes)
[proxmox:children]
proxmox_prod
proxmox_databases
proxmox_webservers

[vmware:children]
vmware_prod
vmware_app

# Groupe all
[all:children]
proxmox
vmware
```

## 🎯 Exemples de ciblage

### Par provider

```bash
# Toutes les VMs Proxmox
ansible proxmox -i inventory/all/inventory.ini -m ping

# Toutes les VMs VMware
ansible vmware -i inventory/all/inventory.ini -m ping
```

### Par environnement (tous providers)

```bash
# Toutes les VMs de production (Proxmox + VMware)
ansible prod -i inventory/all/inventory.ini -m ping

# Toutes les bases de données (Proxmox + VMware)
ansible databases -i inventory/all/inventory.ini -m ping
```

### Par environnement ET provider

```bash
# Seulement la production Proxmox
ansible proxmox_prod -i inventory/all/inventory.ini -m ping

# Seulement la production VMware
ansible vmware_prod -i inventory/all/inventory.ini -m ping
```

### Avec des playbooks

```bash
# Installer les guest agents sur toutes les VMs Proxmox
ansible-playbook -i inventory/all/inventory.ini playbooks/orchestrate.yml --tags qemu-agent --limit proxmox

# Configurer MySQL sur toutes les bases (tous providers)
ansible-playbook -i inventory/all/inventory.ini playbooks/orchestrate.yml --tags mysql --limit databases

# Déployer Dolibarr uniquement sur VMware
ansible-playbook -i inventory/all/inventory.ini playbooks/orchestrate.yml --tags dolibarr --limit vmware
```

## 🔧 Personnalisation

### Ajouter une variable à l'inventaire

Éditer le template correspondant :

**Pour tous les inventaires :**
```bash
vim terraform/templates/inventory.tpl
```

Ajouter des variables :
```django
${vm.name} ansible_host=${vm.ip} ansible_user=ansible custom_var=${vm.custom_field}
```

**Pour l'inventaire global uniquement :**
```bash
vim terraform/templates/inventory-global.tpl
```

### Ajouter un nouveau groupe

1. Ajouter le groupe dans la colonne `ansible_groups` du CSV :
```csv
mysql-prod01,200,prod,pve01,...,"prod,databases,monitoring",...
```

2. Appliquer Terraform :
```bash
cd terraform/ && tofu apply
```

3. Le groupe apparaîtra automatiquement dans l'inventaire

### Variables par groupe

Créer des fichiers `group_vars` :

```bash
# Pour tous les environments prod
mkdir -p ansible/inventory/proxmox/group_vars
cat > ansible/inventory/proxmox/group_vars/prod.yml <<EOF
# Variables pour le groupe prod
backup_enabled: true
monitoring_enabled: true
EOF
```

## 🐛 Troubleshooting

### Inventaire non généré

**Symptôme :** Le fichier `inventory.ini` n'existe pas ou est vide

**Solution :**
```bash
cd terraform/
tofu apply  # Force la régénération
```

### Groupes manquants dans l'inventaire

**Cause :** La colonne `ansible_groups` est vide ou mal formatée dans le CSV

**Solution :**
```bash
# Vérifier le CSV
cat config/vms-proxmox.csv | grep mysql

# Format attendu : "group1,group2,group3" (avec guillemets si virgules)
```

### VM pas dans le bon groupe

**Cause :** Erreur dans la colonne `ansible_groups` du CSV

**Solution :**
1. Corriger le CSV
2. Appliquer Terraform : `cd terraform/ && tofu apply`
3. Vérifier : `grep "mysql" ansible/inventory/proxmox/inventory.ini`

### L'inventaire global ne montre pas les VMs VMware

**Cause :** Le fichier `vms-vmware.csv` est vide ou contient uniquement des lignes commentées

**Solution :**
```bash
# Vérifier le contenu
cat config/vms-vmware.csv

# Ajouter au moins une VM non commentée
vim config/vms-vmware.csv

# Appliquer
cd terraform/ && tofu apply
```

## 📚 Fichiers impliqués

```
terraform/
├── vms-proxmox.tf                    # Génère inventory/proxmox/inventory.ini
├── vms-vmware.tf                     # Génère inventory/vmware/inventory.ini
├── inventory-global.tf               # Génère inventory/all/inventory.ini
└── templates/
    ├── inventory.tpl                 # Template par provider
    └── inventory-global.tpl          # Template global

config/
├── vms-proxmox.csv                   # Source pour Proxmox
└── vms-vmware.csv                    # Source pour VMware

ansible/inventory/
├── proxmox/inventory.ini             # Généré automatiquement
├── vmware/inventory.ini              # Généré automatiquement
└── all/inventory.ini                 # Généré automatiquement
```

## ✅ Checklist

- [ ] CSV Proxmox rempli avec colonne `ansible_groups`
- [ ] CSV VMware rempli (si nécessaire) avec colonne `ansible_groups`
- [ ] `tofu apply` exécuté sans erreur
- [ ] Inventaire Proxmox généré et validé
- [ ] Inventaire VMware généré (si VMs VMware)
- [ ] Inventaire global généré avec les deux providers
- [ ] Test de ping sur tous les groupes réussi
- [ ] Groupes disponibles documentés dans les playbooks
