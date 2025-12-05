# Scripts de déploiement

Infrastructure as Code avec Terraform/OpenTofu et Ansible.

## Architecture

```
scripts/
├── deploy-infrastructure.sh  # Script orchestrateur principal
├── deploy-terraform.sh       # Création VMs (Terraform) - Lecture directe CSV
├── deploy-ansible.sh         # Configuration VMs (Ansible)
└── check-guest-agents.sh     # Vérification des guest agents
```

## Workflow

1. **Configuration** : Éditer les fichiers CSV (`config/vms-proxmox.csv`, `config/vms-vmware.csv`)
2. **Terraform** : Lecture directe des CSV avec `csvdecode()`, aucune génération Python
3. **Création VMs** : Déploiement sur Proxmox et/ou VMware
4. **Génération inventaires** : Terraform génère automatiquement 3 inventaires Ansible :
   - `ansible/inventory/proxmox/` - VMs Proxmox uniquement
   - `ansible/inventory/vmware/` - VMs VMware uniquement
   - `ansible/inventory/all/` - Toutes les VMs avec groupes préfixés
5. **Ansible** : Configuration des VMs via les inventaires générés

## Usage

### Déploiement complet

```bash
# Déployer toute l'infrastructure (VMs + configuration)
./deploy-infrastructure.sh

# Vérifier le plan avant déploiement
./deploy-infrastructure.sh --plan-only

# Déployer uniquement Terraform
./deploy-infrastructure.sh --terraform-only

# Déployer uniquement Ansible
./deploy-infrastructure.sh --ansible-only
```

### Terraform seul

```bash
# Plan uniquement
./deploy-terraform.sh --plan-only

# Appliquer automatiquement
./deploy-terraform.sh --auto-apply

# Valider la configuration
./deploy-terraform.sh --validate-only
```

### Ansible seul

```bash
# Configurer toutes les VMs (inventaire all/)
./deploy-ansible.sh

# Utiliser un inventaire spécifique
./deploy-ansible.sh --inventory proxmox
./deploy-ansible.sh --inventory vmware
./deploy-ansible.sh --inventory all

# Augmenter le parallélisme
./deploy-ansible.sh --parallel 5

# Cibler des groupes spécifiques
./deploy-ansible.sh --tags "common,security"
```

## Options principales

### deploy-terraform.sh

| Option | Description |
|--------|-------------|
| `--plan-only` | Génère le plan Terraform sans l'appliquer |
| `--auto-apply` | Applique automatiquement sans confirmation |
| `--validate-only` | Valide uniquement la syntaxe |
| `--no-refresh` | Désactive le refresh de l'état |

### deploy-ansible.sh

| Option | Description |
|--------|-------------|
| `--inventory <type>` | Choisir l'inventaire : proxmox, vmware, all (défaut: all) |
| `--parallel <num>` | Nombre de VMs en parallèle (défaut: 3, max: 5) |
| `--tags <tags>` | Tags Ansible à exécuter |
| `--skip-tags <tags>` | Tags Ansible à ignorer |

## Fichiers de configuration

### CSV Proxmox (`config/vms-proxmox.csv`)

Colonnes :
- `name` : Nom de la VM
- `vmid` : ID unique Proxmox
- `environment` : prod, preprod, dev
- `node` : Nœud Proxmox cible
- `description` : Description
- `cores`, `memory`, `disk_size` : Ressources
- `ip`, `gateway`, `mac` : Configuration réseau
- `tags` : Tags Proxmox (séparés par virgules)
- `ansible_groups` : Groupes Ansible (séparés par virgules)
- `playbooks` : Playbooks à exécuter (séparés par virgules)
- `playbook_vars` : Variables (format: key=value;key2=value2)
- Variables spécifiques : `db_backup_file`, `documents_backup_file`, `dolibarr_domain`, `git_repo_url`, `git_branch`

### CSV VMware (`config/vms-vmware.csv`)

Colonnes similaires mais avec :
- `datacenter` : Datacenter VMware
- `cluster` : Cluster VMware
- `datastore` : Datastore VMware
(remplacent la colonne `node`)

## Inventaires Ansible générés

### Structure

```
ansible/inventory/
├── proxmox/
│   └── inventory.ini          # VMs Proxmox uniquement
├── vmware/
│   └── inventory.ini          # VMs VMware uniquement
└── all/
    └── inventory.ini          # Toutes les VMs avec préfixes
```

### Groupes dans l'inventaire `all/`

Les groupes sont préfixés par provider :
- `proxmox_prod`, `proxmox_mysql`, etc.
- `vmware_prod`, `vmware_appservers`, etc.

Groupes combinés (tous providers) :
- `all_prod`, `all_mysql`, etc.

## Cas d'usage

### Ajouter une nouvelle VM Proxmox

1. Éditer `config/vms-proxmox.csv`
2. Ajouter la ligne avec toutes les informations
3. Déployer :
   ```bash
   ./deploy-terraform.sh --plan-only  # Vérifier
   ./deploy-terraform.sh --auto-apply # Créer
   ./deploy-ansible.sh --inventory proxmox  # Configurer
   ```

### Ajouter une VM VMware

1. Éditer `config/vms-vmware.csv`
2. Utiliser les colonnes datacenter/cluster/datastore
3. Déployer de la même manière

### Reconfigurer une VM existante

```bash
# Via l'inventaire
./deploy-ansible.sh --inventory proxmox

# Ou directement avec Ansible
cd /root/ansible
ansible-playbook playbooks/post-installation.yml \
  -l dolibarr-dev01 \
  -i inventory/proxmox/inventory.ini
```

### Vérifier les guest agents

```bash
./check-guest-agents.sh

# Sortie :
# ✅ mysql-prod01 (200): QEMU agent actif
# ✅ app-prod01 (1001): VMware Tools actif
# ❌ web-prod01 (1002): Agent non détecté
```

## Vérifications

### État Terraform

```bash
cd /root/terraform
tofu state list
tofu state show proxmox_virtual_environment_vm.proxmox_vms[\"mysql-prod01\"]
```

### Inventaires générés

```bash
# Lister les hosts
cd /root/ansible
ansible-inventory -i inventory/all/inventory.ini --list

# Tester la connectivité
ansible all -m ping -i inventory/proxmox/inventory.ini
ansible all -m ping -i inventory/vmware/inventory.ini
ansible all -m ping -i inventory/all/inventory.ini
```

### Afficher les VMs par provider

```bash
cd /root/terraform
tofu output infrastructure_summary

# Sortie :
# Proxmox VMs: 4
# VMware VMs: 2
# Total VMs: 6
```

## Troubleshooting

### Erreur "CSV parse error"

Les CSV ne supportent pas les commentaires. Supprimer les lignes commençant par `#`.

### Erreur "file not found: cloudinit/vendor-config.yaml"

Vérifier que les chemins dans `vms-proxmox.tf` et `vms-vmware.tf` pointent vers :
- `cloudinit/vendor-config-proxmox.yaml` pour Proxmox
- `cloudinit/vendor-config-vmware.yaml` pour VMware

### Terraform ne voit pas les changements CSV

```bash
cd /root/terraform
rm -rf .terraform .terraform.lock.hcl
tofu init
```

### Ansible ne trouve pas les hosts

Vérifier que les inventaires sont générés :
```bash
ls -la /root/ansible/inventory/*/inventory.ini
cat /root/ansible/inventory/all/inventory.ini
```

### Guest agent non détecté après création VM

Attendre 2-3 minutes que cloud-init termine :
```bash
# Proxmox
ansible proxmox_vms -m shell -a "cloud-init status --wait" \
  -i /root/ansible/inventory/proxmox/inventory.ini

# VMware
ansible vmware_vms -m shell -a "systemctl status vmtoolsd" \
  -i /root/ansible/inventory/vmware/inventory.ini
```

## Documentation complète

Voir la documentation dans `docs/` :
- `GUIDE-OPERATIONS.md` : Guide opérationnel complet
- `INVENTAIRES-ANSIBLE.md` : Détails sur les inventaires
- `SCHEMA-INVENTAIRES.md` : Schéma visuel du système
