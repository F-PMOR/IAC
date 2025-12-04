# Scripts de déploiement

Cette infrastructure utilise une approche modulaire avec séparation entre Terraform et Ansible.

## Architecture

```
scripts/
├── deploy-infrastructure.sh  # Script orchestrateur principal
├── deploy-terraform.sh       # Création VMs (Terraform)
└── deploy-ansible.sh         # Configuration VMs (Ansible)
```

## Workflow

1. **CSV → YAML** : Conversion de la configuration centralisée
2. **YAML → Terraform** : Génération des fichiers `.tf` via templates Jinja2
3. **Terraform** : Création/mise à jour des VMs sur Proxmox
4. **Ansible** : Configuration des VMs (système, applications, etc.)

## Usage

### Déploiement complet (recommandé)

```bash
# Déployer toute l'infrastructure (VMs + configuration)
/root/scripts/deploy-infrastructure.sh

# Déployer uniquement les nouvelles VMs
/root/scripts/deploy-infrastructure.sh --skip-existing
```

### Déploiement par étape

```bash
# 1. Plan Terraform uniquement (vérification)
/root/scripts/deploy-infrastructure.sh --plan-only

# 2. Créer les VMs avec Terraform
/root/scripts/deploy-infrastructure.sh --terraform-only

# 3. Configurer les VMs avec Ansible
/root/scripts/deploy-infrastructure.sh --ansible-only
```

### Scripts individuels

#### Terraform seul

```bash
# Plan uniquement
/root/scripts/deploy-terraform.sh --plan-only

# Créer les VMs
/root/scripts/deploy-terraform.sh --auto-apply
```

#### Ansible seul

```bash
# Configurer toutes les VMs
/root/scripts/deploy-ansible.sh

# Configurer uniquement les nouvelles VMs
/root/scripts/deploy-ansible.sh --skip-existing

# Augmenter le parallélisme
/root/scripts/deploy-ansible.sh --parallel 5
```

## Options principales

| Option | Description |
|--------|-------------|
| `--skip-existing` | Configure uniquement les nouvelles VMs (détectées par Terraform) |
| `--terraform-only` | Exécute uniquement la partie Terraform (création VMs) |
| `--ansible-only` | Exécute uniquement la partie Ansible (configuration VMs) |
| `--plan-only` | Génère le plan Terraform sans l'appliquer |
| `--parallel NUM` | Nombre de VMs Ansible en parallèle (défaut: 3, max: 5) |

## Cas d'usage courants

### Ajouter une nouvelle VM

1. Ajouter la ligne dans `config/vms.csv`
2. Déployer avec mode skip_existing :
   ```bash
   /root/scripts/deploy-infrastructure.sh --skip-existing
   ```

### Mettre à jour une VM existante

```bash
# Option 1: Reconfigurer toutes les VMs
/root/scripts/deploy-ansible.sh

# Option 2: Cibler une VM spécifique
cd /root/ansible
ansible-playbook playbooks/post-installation.yml -l dolibarr-dev01 -i inventory/proxmox/inventory.ini

# Option 3: Exécuter un playbook spécifique
ansible-playbook playbooks/deploy-dolibarr.yml -l dolibarr-dev01 -i inventory/proxmox/inventory.ini
```

### Vérifier les changements avant déploiement

```bash
# Voir ce que Terraform va faire
/root/scripts/deploy-terraform.sh --plan-only

# Voir le plan en détail
cd /root/terraform
tofu show tfplan
```

### Destruction de VMs

```bash
# Lister les VMs
/root/scripts/destroy-vms.sh --list

# Plan de destruction
/root/scripts/destroy-vms.sh --plan --vm dolibarr-dev02

# Détruire une VM
/root/scripts/destroy-vms.sh --vm dolibarr-dev02

# Détruire toutes les VMs
/root/scripts/destroy-vms.sh --all
```

## Détection des nouvelles VMs

Quand `--skip-existing` est utilisé :

1. Terraform génère le plan et identifie les ressources à créer
2. La liste des nouvelles VMs est sauvegardée dans `config/newly-created-vms.txt`
3. Ansible lit ce fichier et ne configure que ces VMs
4. Les VMs existantes sont ignorées

## Performance

- **Terraform** : Parallélisme fixe à 10 VMs simultanées
- **Ansible** : Parallélisme configurable (défaut: 3, max recommandé: 5)

```bash
# Augmenter le parallélisme Ansible
/root/scripts/deploy-infrastructure.sh --parallel 5
```

## Logs et debugging

```bash
# Voir les logs Terraform en détail
cd /root/terraform
tofu plan
tofu show tfplan

# Voir l'état Terraform
tofu state list
tofu state show proxmox_vm_qemu.dolibarr-dev01

# Tester la connectivité Ansible
cd /root/ansible
ansible all -m ping -i inventory/proxmox/inventory.ini

# Mode verbose Ansible
ansible-playbook playbooks/configure-vms.yml -vvv -i inventory/proxmox/inventory.ini
```

## Fichiers générés

- `config/vms-config.yml` : Configuration YAML générée depuis le CSV
- `terraform/vms-from-config.tf` : Fichier Terraform généré
- `terraform/tfplan` : Plan Terraform binaire
- `config/newly-created-vms.txt` : Liste des VMs nouvellement créées

## Workflow recommandé

### Pour le développement

```bash
# 1. Modifier config/vms.csv
# 2. Vérifier le plan
/root/scripts/deploy-infrastructure.sh --plan-only

# 3. Déployer uniquement les nouvelles VMs
/root/scripts/deploy-infrastructure.sh --skip-existing
```

### Pour la production

```bash
# 1. Modifier config/vms.csv
# 2. Vérifier le plan
/root/scripts/deploy-terraform.sh --plan-only

# 3. Appliquer Terraform
/root/scripts/deploy-terraform.sh --auto-apply

# 4. Vérifier que les VMs sont up
ansible all -m ping -i inventory/proxmox/inventory.ini

# 5. Configurer avec Ansible
/root/scripts/deploy-ansible.sh
```

## Troubleshooting

### Terraform bloqué

```bash
cd /root/terraform
tofu state list
tofu state rm proxmox_vm_qemu.vm-problematic  # Si nécessaire
```

### Ansible ne peut pas se connecter

```bash
# Vérifier la connectivité
ansible all -m ping -i inventory/proxmox/inventory.ini

# Vérifier l'inventaire
ansible-inventory -i inventory/proxmox/inventory.ini --list

# Attendre cloud-init
sleep 60
```

### Fichiers de configuration désynchronisés

```bash
# Regénérer la config
cd /root/config
python3 csv-to-config.py

# Vérifier
cat vms-config.yml
```
