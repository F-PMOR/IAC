# Guide d'Exploitation

Guide pratique pour gérer l'infrastructure au quotidien.

## 🚀 Opérations courantes

### Déployer une nouvelle VM

```bash
# 1. Ajouter la VM dans le CSV approprié
vim config/vms-proxmox.csv  # ou vms-vmware.csv

# 2. Déployer
./scripts/deploy-terraform-v2.sh --auto-apply

# 3. Configurer avec Ansible
./scripts/deploy-ansible.sh --limit nouvelle-vm --tags post-install
```

### Modifier une VM existante

```bash
# 1. Éditer le CSV
vim config/vms-proxmox.csv

# 2. Appliquer les changements
cd terraform/
tofu apply

# 3. Si nécessaire, reconfigurer avec Ansible
cd ..
./scripts/deploy-ansible.sh --limit vm-modifiee
```

### Supprimer une VM

```bash
# 1. Destroy avec Terraform
cd terraform/
tofu destroy -target='proxmox_virtual_environment_vm.proxmox_vms["vm_name"]'

# 2. Retirer du CSV (ou commenter avec #)
vim ../config/vms-proxmox.csv

# 3. Vérifier l'état
tofu state list
```

### Voir l'état de l'infrastructure

```bash
cd terraform/

# Lister toutes les ressources
tofu state list

# Voir les détails d'une VM
tofu state show 'proxmox_virtual_environment_vm.proxmox_vms["mysql_prod01"]'

# Résumé de l'infrastructure
tofu output infrastructure_summary
```

## 📋 Gestion des inventaires Ansible

Les inventaires sont générés automatiquement par Terraform.

### Régénérer les inventaires

```bash
cd terraform/
tofu apply  # Régénère tous les inventaires
```

### Vérifier les inventaires

```bash
# Proxmox
cat ansible/inventory/proxmox/inventory.ini

# VMware
cat ansible/inventory/vmware/inventory.ini

# Global (tous providers)
cat ansible/inventory/all/inventory.ini
```

### Utiliser un inventaire spécifique

```bash
# Proxmox (par défaut)
./scripts/deploy-ansible.sh

# VMware
INVENTORY_FILE=./ansible/inventory/vmware/inventory.ini ./scripts/deploy-ansible.sh

# Tous les providers
INVENTORY_FILE=./ansible/inventory/all/inventory.ini ./scripts/deploy-ansible.sh
```

## 🔧 Configuration Ansible

### Configuration complète d'une VM

```bash
# Post-installation + tous les rôles
./scripts/deploy-ansible.sh --limit mysql-prod01
```

### Configuration par tags

```bash
# Uniquement les guest agents
./scripts/deploy-ansible.sh --tags agent

# Uniquement MySQL
./scripts/deploy-ansible.sh --tags mysql --limit databases

# Uniquement Dolibarr
./scripts/deploy-ansible.sh --tags dolibarr --limit dolibarr
```

### Configuration par environnement

```bash
# Toute la production
./scripts/deploy-ansible.sh --limit prod

# Tout le dev
./scripts/deploy-ansible.sh --limit dev

# Production Proxmox uniquement (avec inventaire global)
INVENTORY_FILE=./ansible/inventory/all/inventory.ini \
  ./scripts/deploy-ansible.sh --limit proxmox_prod
```

### Mode dry-run (voir sans appliquer)

```bash
./scripts/deploy-ansible.sh --check --limit mysql-prod01
```

## 🎯 Scénarios courants

### Ajouter un serveur MySQL en production

```bash
# 1. Éditer le CSV
vim config/vms-proxmox.csv

# Ajouter :
# mysql-prod02,205,prod,pve02,MySQL Production Replica,4,8192,100,192.168.1.105,192.168.1.1,BC:24:11:44:BF:15,"terraform,prod,database","prod,databases","post-installation.yml,setup-mysql.yml",,,,,

# 2. Créer la VM
./scripts/deploy-terraform-v2.sh --auto-apply

# 3. Configurer
./scripts/deploy-ansible.sh --limit mysql-prod02 --tags post-install,mysql
```

### Ajouter un serveur Dolibarr en preprod

```bash
# 1. Éditer le CSV
vim config/vms-proxmox.csv

# Ajouter :
# dolibarr-preprod02,212,preprod,pve01,Dolibarr PreProd 2,2,2048,30,192.168.1.112,192.168.1.1,BC:24:11:44:BF:12,"terraform,preprod,web","preprod,webservers,dolibarr","post-installation.yml,deploy-dolibarr.yml",,,,dolibarr-preprod2.morry.fr,,

# 2. Créer la VM
./scripts/deploy-terraform-v2.sh --auto-apply

# 3. Configurer
./scripts/deploy-ansible.sh --limit dolibarr-preprod02 --tags post-install,dolibarr
```

### Augmenter la mémoire d'une VM

```bash
# 1. Modifier dans le CSV (colonne memory)
vim config/vms-proxmox.csv
# Changer : ...,4096,... en ...,8192,...

# 2. Appliquer (attention : peut nécessiter un redémarrage)
cd terraform/
tofu apply

# 3. Vérifier sur la VM
ssh ansible@192.168.1.100 free -h
```

### Changer l'IP d'une VM

```bash
# 1. Modifier dans le CSV (colonne ip)
vim config/vms-proxmox.csv

# 2. Appliquer avec Terraform
cd terraform/
tofu apply

# 3. Mettre à jour l'inventaire (automatique avec apply)
# 4. Tester la connexion
ansible mysql-prod01 -i ansible/inventory/proxmox/inventory.ini -m ping
```

## 🐛 Dépannage

### Terraform : Erreur de parsing CSV

**Symptôme** :
```
Error: Invalid CSV format
```

**Solution** :
```bash
# Vérifier la syntaxe
python3 -c "import csv; list(csv.DictReader(open('config/vms-proxmox.csv')))"

# Vérifier les guillemets et virgules
cat config/vms-proxmox.csv | head
```

### Terraform : VM existe déjà dans Proxmox

**Symptôme** :
```
Error: VM with ID 200 already exists
```

**Solution** :
```bash
# Option 1 : Importer la VM dans le state
cd terraform/
tofu import 'proxmox_virtual_environment_vm.proxmox_vms["mysql_prod01"]' pve01/200

# Option 2 : Changer le VMID dans le CSV
vim config/vms-proxmox.csv
```

### Ansible : VM non joignable

**Symptôme** :
```
UNREACHABLE! => {"changed": false, "msg": "Failed to connect"}
```

**Solution** :
```bash
# 1. Vérifier la connectivité
ping 192.168.1.100

# 2. Vérifier SSH
ssh ansible@192.168.1.100

# 3. Vérifier l'inventaire
cat ansible/inventory/proxmox/inventory.ini | grep mysql-prod01

# 4. Régénérer l'inventaire
cd terraform/ && tofu apply
```

### Guest Agent non installé

**Symptôme** :
```
Warning: QEMU guest agent is not running
```

**Solution** :
```bash
# Installer avec Ansible
./scripts/deploy-ansible.sh --tags agent --limit mysql-prod01

# Ou manuellement sur la VM
ssh ansible@192.168.1.100
sudo apt update && sudo apt install -y qemu-guest-agent
sudo systemctl enable --now qemu-guest-agent
```

### Terraform lent ou timeout

**Symptôme** :
```
Still creating... [3m0s elapsed]
```

**Solution** :
```bash
# Utiliser --no-refresh pour les plans
./scripts/deploy-terraform-v2.sh --plan-only --no-refresh

# Pour apply, le refresh est souvent nécessaire
cd terraform/
tofu apply -refresh-only  # D'abord refresh seul
tofu apply                # Puis apply normal
```

## 📊 Monitoring et vérification

### Vérifier l'état des VMs

```bash
# Depuis Terraform
cd terraform/
tofu state list | grep proxmox_vms

# Depuis Ansible (ping toutes les VMs)
ansible all -i ansible/inventory/proxmox/inventory.ini -m ping

# Par groupe
ansible databases -i ansible/inventory/proxmox/inventory.ini -m ping
ansible prod -i ansible/inventory/proxmox/inventory.ini -m ping
```

### Vérifier les guest agents

```bash
# Script de vérification
./scripts/check-guest-agents.sh

# Ou manuellement
ansible all -i ansible/inventory/proxmox/inventory.ini \
  -m shell -a "systemctl status qemu-guest-agent" -b
```

### Statistiques de l'infrastructure

```bash
# Nombre de VMs par provider
wc -l config/vms-proxmox.csv config/vms-vmware.csv

# Via Terraform
cd terraform/
tofu output infrastructure_summary

# Par environnement
grep ",prod," config/vms-proxmox.csv | wc -l   # VMs prod
grep ",dev," config/vms-proxmox.csv | wc -l    # VMs dev
```

## 🔐 Sécurité et backups

### Backup des CSV

```bash
# Backup quotidien
cp config/vms-proxmox.csv config/backups/vms-proxmox-$(date +%Y%m%d).csv

# Versionner avec Git
git add config/vms-proxmox.csv
git commit -m "Add new VM: mysql-prod02"
git push
```

### Backup du state Terraform

```bash
# Backup manuel
cp terraform/terraform.tfstate terraform/terraform.tfstate.$(date +%Y%m%d-%H%M)

# Le state est automatiquement backupé dans .tfstate.backup
ls -lh terraform/*.tfstate*
```

### Rotation des credentials

```bash
# 1. Changer les mots de passe dans cloud-init
vim terraform/cloudinit/user-config.yaml

# 2. Appliquer sur les nouvelles VMs uniquement
# (Les VMs existantes gardent leur config actuelle)

# 3. Pour mettre à jour les VMs existantes, utiliser Ansible
# ansible-playbook playbooks/update-passwords.yml
```

## 📚 Ressources

- Structure CSV : `config/README-CSV-PROVIDERS.md`
- Inventaires : `docs/INVENTAIRES-ANSIBLE.md`
- Guest agents : `ansible/playbooks/README-GUEST-AGENTS.md`
- Terraform : `terraform/README.md`
