# Structure du dossier Terraform

## 📁 Organisation des fichiers

### ⭐ Fichiers de configuration (versionnés dans Git)

Ces fichiers définissent votre infrastructure et **doivent être versionnés** :

```
provider.tf                    # Configuration du provider Proxmox
provider-vmware.tf             # Configuration du provider VMware
variables.tf                   # Déclaration des variables Terraform
terraform.tfvars               # Valeurs des variables (mots de passe, URLs, etc.)
vms-from-config-proxmox.tf     # Définition des VMs Proxmox depuis CSV
vms-from-config-vmware.tf      # Définition des VMs VMware depuis CSV
ignore-existing-vms.tf         # Ignorer les VMs existantes hors IaC
```

### 📝 Templates (versionnés)

```
templates/
  └── inventory.tpl            # Template pour générer l'inventaire Ansible

cloudinit/
  ├── user-config.yaml         # Configuration utilisateurs cloud-init
  └── vendor-config.yaml       # Configuration système cloud-init
```

### 🗑️ Fichiers générés (exclus par .gitignore)

Ces fichiers sont **automatiquement générés** et ne doivent **PAS être versionnés** :

```
terraform.tfstate              # État actuel de l'infrastructure (SENSIBLE!)
terraform.tfstate.backup       # Sauvegarde du state
.terraform.tfstate.lock.info   # Fichier de lock temporaire
.terraform/                    # Providers téléchargés et cache
.terraform.lock.hcl            # Lock des versions de providers
tfplan                         # Plan binaire temporaire
```

### 📦 Autres dossiers

```
disabled/                      # Anciennes configurations désactivées
```

## 🔄 Régénération des fichiers

### State Terraform (`terraform.tfstate`)

Pour reconstruire le state depuis zéro :

```bash
cd /root/terraform
rm -f terraform.tfstate terraform.tfstate.backup .terraform.tfstate.lock.info
cd /root/scripts
python3 build-terraform-state.py
cd /root/terraform
tofu apply -refresh-only -auto-approve
```

### Providers et cache (`.terraform/`)

Pour réinitialiser les providers :

```bash
cd /root/terraform
rm -rf .terraform .terraform.lock.hcl
tofu init
```

### Fichiers cloud-init sur Proxmox

Les fichiers cloud-init dans Proxmox (`local:snippets/`) sont automatiquement créés/mis à jour par `tofu apply`.

### Inventaire Ansible

L'inventaire Ansible est automatiquement généré par Terraform lors du `tofu apply` grâce à la ressource `local_file.ansible_inventory_csv`.

## ⚠️ Fichiers sensibles

Le fichier `terraform.tfstate` contient des **informations sensibles** :
- Adresses IP des VMs
- Configurations système
- Possibles mots de passe en clair

**Ne JAMAIS versionner le tfstate !** Il est automatiquement exclu par le `.gitignore`.

## 📋 Commandes utiles

```bash
# Vérifier la structure
tofu validate

# Voir les ressources gérées
tofu state list

# Voir les changements prévus
tofu plan

# Appliquer les changements
tofu apply

# Nettoyer et réinitialiser
rm -rf .terraform terraform.tfstate*
tofu init
python3 ../scripts/build-terraform-state.py
```
