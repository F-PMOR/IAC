# Migration vers la gestion CSV

## Problème actuel

Vous avez 2 systèmes de gestion de VMs :
1. **`terraform/vms.tf`** - Configuration manuelle (existant)
2. **`config/vms.csv`** - Configuration centralisée (nouveau)

Terraform essaie de créer les VMs des deux sources, ce qui cause des conflits.

## Solution : Choisir un système

### Option 1 : Utiliser uniquement le CSV (recommandé)

```bash
# 1. Renommer l'ancien fichier pour le désactiver
cd terraform
mv vms.tf vms.tf.disabled
mv inventory.tf inventory.tf.disabled

# 2. Générer la config depuis le CSV
cd ../
python3 config/csv-to-config.py

# 3. Lancer l'orchestrateur
cd ansible/playbooks
ansible-playbook orchestrate-deployment.yml -e auto_apply=true
```

### Option 2 : Garder les 2 systèmes séparés

```bash
# Renommer le fichier généré pour éviter les conflits
cd terraform
mv vms-from-config.tf vms-from-config.tf.disabled

# Utiliser seulement vms.tf comme avant
```

## Workflow recommandé avec CSV

```
┌──────────────┐
│  vms.csv     │  ← Éditer ici (Excel/Calc)
└──────┬───────┘
       │
       ↓ python3 config/csv-to-config.py
       │
┌──────────────┐
│vms-config.yml│  ← Config générée
└──────┬───────┘
       │
       ↓ orchestrate-deployment.yml
       │
┌──────────────┐
│ Déploiement  │  ← Terraform + Ansible
└──────────────┘
```

## Commandes rapides

### Générer et déployer

```bash
# Générer la configuration
python3 config/csv-to-config.py

# Déployer (sans auto-apply)
ansible-playbook playbooks/orchestrate-deployment.yml

# Déployer (avec auto-apply)
ansible-playbook playbooks/orchestrate-deployment.yml -e auto_apply=true
```

### Nettoyer l'état Terraform

Si vous avez des VMs en double ou des erreurs :

```bash
cd terraform

# Lister les ressources
tofu state list

# Supprimer une ressource de l'état (sans détruire la VM)
tofu state rm 'proxmox_virtual_environment_vm.dolibarr_dev01'

# Ou tout nettoyer et recommencer
rm -f terraform.tfstate terraform.tfstate.backup tfplan
tofu init
```

## Dépannage

### Erreur: "non-existent or non-regular file"

**Cause** : Conflit entre vms.tf et vms-from-config.tf

**Solution** :
```bash
cd terraform
mv vms.tf vms.tf.disabled
# OU
mv vms-from-config.tf vms-from-config.tf.disabled
```

### Erreur: "resource already exists"

**Cause** : VM déjà créée avec un autre nom de ressource

**Solution** :
```bash
# Supprimer de l'état Terraform
tofu state rm 'proxmox_virtual_environment_vm.OLD_NAME'

# Importer la VM existante
tofu import 'proxmox_virtual_environment_vm.vms_csv["NEW_NAME"]' VMID
```

### Les playbooks ne s'exécutent pas

**Cause** : `auto_apply=false` par défaut

**Solution** :
```bash
ansible-playbook playbooks/orchestrate-deployment.yml -e auto_apply=true
```

## Recommandation finale

**Utilisez le système CSV** pour centraliser toute la configuration :

1. Désactivez `vms.tf` : `mv terraform/vms.tf terraform/vms.tf.disabled`
2. Éditez `config/vms.csv` pour toutes vos VMs
3. Utilisez `orchestrate-deployment.yml` pour tout déployer

Avantages :
✅ Une seule source de vérité (le CSV)
✅ Facile à éditer (Excel/Calc)
✅ Déploiement automatique end-to-end
✅ Playbooks configurables par VM
