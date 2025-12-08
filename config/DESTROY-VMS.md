# Destruction des VMs Terraform

## 🗑️ Commandes rapides

### Lister les VMs
```bash
list-vms
# ou
cd /root/terraform
tofu state list
```

### Détruire une VM spécifique
```bash
# Avec l'alias
destroy-vm dolibarr-dev01

# Ou directement
cd /root/terraform
tofu destroy -target='proxmox_virtual_environment_vm.vms_csv["dolibarr_dev01"]' -auto-approve
```

### Détruire toutes les VMs
```bash
# Avec l'alias (demande confirmation)
destroy-all-vms

# Ou directement
cd /root/terraform
tofu destroy -auto-approve
```

## 📋 Méthodes détaillées

### 1. Destruction ciblée d'une VM

```bash
cd /root/terraform

# Voir ce qui sera détruit
tofu plan -destroy -target='proxmox_virtual_environment_vm.vms_csv["dolibarr_dev01"]'

# Détruire
tofu destroy -target='proxmox_virtual_environment_vm.vms_csv["dolibarr_dev01"]'
```

**Important** : Le nom dans Terraform utilise des underscores :
- CSV : `dolibarr-dev01`
- Terraform : `dolibarr_dev01` (tirets → underscores)

### 2. Destruction de plusieurs VMs

```bash
cd /root/terraform

# Détruire dev et preprod
tofu destroy \
  -target='proxmox_virtual_environment_vm.vms_csv["dolibarr_dev01"]' \
  -target='proxmox_virtual_environment_vm.vms_csv["dolibarr_preprod01"]'
```

### 3. Destruction de tout

```bash
cd /root/terraform

# Détruire TOUT (VMs + cloud-init + images)
tofu destroy

# Détruire seulement les VMs
tofu destroy -target='proxmox_virtual_environment_vm.vms_csv'
```

## 🔍 Vérifications avant destruction

### Voir l'état d'une VM
```bash
cd /root/terraform
tofu state show 'proxmox_virtual_environment_vm.vms_csv["dolibarr_dev01"]'
```

### Lister toutes les ressources
```bash
cd /root/terraform
tofu state list

# Filtrer les VMs
tofu state list | grep vms_csv
```

### Voir ce qui sera détruit (dry-run)
```bash
cd /root/terraform
tofu plan -destroy
```

## 🔄 Recréer une VM

### Supprimer et recréer proprement
```bash
# 1. Détruire la VM
destroy-vm dolibarr-dev01

# 2. Recréer avec orchestrate
orchestrate-apply
```

### Forcer le remplacement (taint)
```bash
cd /root/terraform

# Marquer comme "à remplacer"
tofu taint 'proxmox_virtual_environment_vm.vms_csv["dolibarr_dev01"]'

# Appliquer (détruit + recrée)
tofu apply
```

## 🧹 Nettoyage complet

### Supprimer toutes les VMs et recommencer
```bash
cd /root/terraform

# 1. Tout détruire
tofu destroy -auto-approve

# 2. Nettoyer l'état
rm -f terraform.tfstate terraform.tfstate.backup tfplan

# 3. Réinitialiser
tofu init

# 4. Redéployer
cd /root
orchestrate-apply
```

## ⚠️ Précautions

### Sauvegardes
Avant de détruire une VM en production :
```bash
# 1. Sauvegarder les données
ssh ansible@192.168.1.101 'sudo tar czf /tmp/backup.tar.gz /var/www /etc'

# 2. Copier la sauvegarde
scp ansible@192.168.1.101:/tmp/backup.tar.gz ~/backups/

# 3. Détruire
destroy-vm dolibarr-prod01
```

### Snapshots Proxmox
Créer un snapshot avant destruction (depuis Proxmox) :
```bash
pvesh create /nodes/pve01/qemu/106/snapshot -snapname before_destroy
```

## 🐛 Dépannage

### VM pas dans l'état Terraform
```bash
# Si la VM existe dans Proxmox mais pas dans Terraform
# L'importer d'abord
tofu import 'proxmox_virtual_environment_vm.vms_csv["dolibarr_dev01"]' 106
```

### Erreur "resource not found"
```bash
# La VM n'existe plus dans Proxmox mais est dans l'état
# Supprimer de l'état
tofu state rm 'proxmox_virtual_environment_vm.vms_csv["dolibarr_dev01"]'
```

### Destruction bloquée
```bash
# Forcer la suppression (dangereux!)
tofu destroy -target='proxmox_virtual_environment_vm.vms_csv["dolibarr_dev01"]' -auto-approve -lock=false
```

## 📊 Exemples pratiques

### Scénario 1 : Recréer l'environnement dev
```bash
# Supprimer dev
destroy-vm dolibarr-dev01

# Attendre 10 secondes
sleep 10

# Recréer
orchestrate-apply
```

### Scénario 2 : Nettoyer tous les environnements de test
```bash
cd /root/terraform

# Détruire dev et preprod
tofu destroy \
  -target='proxmox_virtual_environment_vm.vms_csv["dolibarr_dev01"]' \
  -target='proxmox_virtual_environment_vm.vms_csv["dolibarr_preprod01"]' \
  -auto-approve
```

### Scénario 3 : Migrer une VM vers un autre node
```bash
# 1. Sauvegarder
ansible-playbook playbooks/backup-vm.yml --limit dolibarr-dev01

# 2. Détruire l'ancienne
destroy-vm dolibarr-dev01

# 3. Modifier le CSV (changer le node)
nano /root/config/vms.csv

# 4. Régénérer et déployer
csv2yaml
orchestrate-apply

# 5. Restaurer les données
ansible-playbook playbooks/restore-vm.yml --limit dolibarr-dev01
```

## 🔐 Aliases disponibles

```bash
list-vms              # Liste les VMs Terraform
destroy-vm <name>     # Détruit une VM
destroy-all-vms       # Détruit toutes les VMs
```

## 📝 Notes importantes

1. **Cloud-init files** : Sont également supprimés avec la VM
2. **Images Debian** : Restent sur le node (réutilisées)
3. **Inventaire Ansible** : Est régénéré automatiquement
4. **État Terraform** : Est mis à jour automatiquement
5. **Confirmation** : Le script demande confirmation avant destruction
