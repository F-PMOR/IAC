# Infrastructure as Code - Proxmox & VMware

Gestion d'infrastructure multi-provider (Proxmox VE, VMware vSphere) avec Terraform/OpenTofu et Ansible.

## 🎯 Architecture

- **Terraform/OpenTofu** : Provisionnement des VMs (création, configuration réseau, disques)
- **Ansible** : Configuration post-déploiement (packages, services, applications)
- **CSV par provider** : Source unique de vérité pour chaque infrastructure
- **Cloud-init** : Installation automatique des guest agents (QEMU, VMware Tools)

## 📁 Structure du projet

```
├── config/
│   ├── vms-proxmox.csv         # Configuration VMs Proxmox
│   ├── vms-vmware.csv          # Configuration VMs VMware
│   └── README-CSV-PROVIDERS.md # Documentation des CSV
├── terraform/
│   ├── vms-proxmox.tf          # Ressources Terraform Proxmox
│   ├── vms-vmware.tf           # Ressources Terraform VMware
│   ├── provider-proxmox.tf     # Configuration provider Proxmox
│   ├── provider-vmware.tf      # Configuration provider VMware
│   └── cloudinit/              # Fichiers cloud-init (user/vendor)
├── ansible/
│   ├── inventory/              # Inventaires générés par Terraform
│   └── playbooks/              # Playbooks de configuration
│       ├── install-qemu-agent.yml
│       ├── install-vmware-tools.yml
│       └── orchestrate.yml
└── scripts/
    ├── deploy-terraform-v2.sh  # Déploiement Terraform
    ├── deploy-ansible.sh       # Configuration Ansible
    └── check-guest-agents.sh   # Vérification des agents
```

## 🚀 Démarrage rapide

### 1. Construction et démarrage du conteneur


Construire l'image personnalisée avec bash :
```bash
podman-compose build
```

Démarrer le conteneur :
```bash
podman-compose up -d
```

### 2. Configuration de l'infrastructure

Éditer les fichiers CSV selon vos besoins :

**Pour Proxmox :**
```bash
vim config/vms-proxmox.csv
```

**Pour VMware :**
```bash
vim config/vms-vmware.csv
```

### 3. Déploiement

**Déployer les VMs avec Terraform :**
```bash
# Voir les changements prévus
./scripts/deploy-terraform-v2.sh --plan-only

# Déployer
./scripts/deploy-terraform-v2.sh --auto-apply
```

**Configurer les VMs avec Ansible :**
```bash
# Installer les guest agents
./scripts/deploy-ansible.sh --tags agent

# Configuration complète (Proxmox uniquement par défaut)
./scripts/deploy-ansible.sh

# Configurer toutes les infrastructures
INVENTORY_FILE=./ansible/inventory/all/inventory.ini ./scripts/deploy-ansible.sh

# Configurer uniquement VMware
INVENTORY_FILE=./ansible/inventory/vmware/inventory.ini ./scripts/deploy-ansible.sh
```

### 4. Inventaires Ansible générés automatiquement

Terraform génère **3 inventaires** lors du `tofu apply` :

1. **`inventory/proxmox/inventory.ini`** : VMs Proxmox uniquement
2. **`inventory/vmware/inventory.ini`** : VMs VMware uniquement  
3. **`inventory/all/inventory.ini`** : Toutes les VMs avec groupes par provider

Voir [`docs/INVENTAIRES-ANSIBLE.md`](docs/INVENTAIRES-ANSIBLE.md) et [`docs/SCHEMA-INVENTAIRES.md`](docs/SCHEMA-INVENTAIRES.md) pour plus de détails.

## 📋 Gestion des VMs

### Ajouter une nouvelle VM

1. Ajouter une ligne dans le CSV approprié (`vms-proxmox.csv` ou `vms-vmware.csv`)
2. Exécuter `./scripts/deploy-terraform-v2.sh --auto-apply`
3. Configurer avec `./scripts/deploy-ansible.sh --limit nouvelle-vm`

### Supprimer une VM

```bash
cd terraform/
tofu destroy -target='proxmox_virtual_environment_vm.proxmox_vms["vm_name"]'
```

Puis retirer la ligne du CSV.

## 🔧 Guest Agents

Les guest agents sont essentiels pour la communication entre l'hyperviseur et les VMs :

- **Proxmox** : QEMU Guest Agent (installé via `cloudinit/vendor-config-proxmox.yaml`)
- **VMware** : VMware Tools / open-vm-tools (installé via `cloudinit/vendor-config-vmware.yaml`)

**Installation manuelle :**
```bash
./scripts/deploy-ansible.sh --tags qemu-agent    # Proxmox
./scripts/deploy-ansible.sh --tags vmware-tools  # VMware
./scripts/deploy-ansible.sh --tags agent         # Les deux
```

**Vérification :**
```bash
./scripts/check-guest-agents.sh
```

Voir `ansible/playbooks/README-GUEST-AGENTS.md` pour plus de détails.

## 📚 Documentation

- **[README-OPERATIONS.md](README-OPERATIONS.md)** : Guide d'exploitation complet
- **[config/README-CSV-PROVIDERS.md](config/README-CSV-PROVIDERS.md)** : Structure des fichiers CSV
- **[MIGRATION-CSV-PROVIDERS.md](MIGRATION-CSV-PROVIDERS.md)** : Guide de migration
- **[ansible/playbooks/README-GUEST-AGENTS.md](ansible/playbooks/README-GUEST-AGENTS.md)** : Guest agents
- **[terraform/README.md](terraform/README.md)** : Organisation Terraform

## 🐳 Utilisation du conteneur

### Connexion au conteneur

Se connecter au conteneur pour exécuter vos playbooks (avec bash pour avoir les alias) :
```bash
podman exec -it ansible-workspace /bin/bash
```

## Exécuter un playbook

Une fois connecté dans le conteneur :
```bash
ansible-playbook votre-playbook.yml
```

Ou directement depuis l'hôte :
```bash
podman exec -it ansible-workspace ansible-playbook votre-playbook.yml
```

## Alias disponibles

Les alias Ansible et OpenTofu sont automatiquement chargés dans bash.

**Ansible :**
- `ap` → `ansible-playbook`
- `apc` → `ansible-playbook --check`
- `apd` → `ansible-playbook --diff`
- `aping` → `ansible all -m ping`
- `ave` → `ansible-vault edit`

**OpenTofu (compatible Terraform) :**
- `tf` → `tofu`
- `tfi` → `tofu init`
- `tfp` → `tofu plan`
- `tfa` → `tofu apply`
- `tfd` → `tofu destroy`
- `tfv` → `tofu validate`
- `tff` → `tofu fmt`

Voir le fichier `.bash_aliases` pour la liste complète.

## Arrêt

Arrêter le conteneur :
```bash
podman-compose down
```

## Reconstruction

Si vous modifiez le Dockerfile :
```bash
podman-compose down
podman-compose build --no-cache
podman-compose up -d
```

## Notes

- Vos playbooks du répertoire courant sont montés dans `/ansible/playbooks`
- Les clés SSH de votre système sont montées en lecture seule dans `/root/.ssh`
- Le conteneur reste actif en arrière-plan pour permettre les connexions
- Les variables d'environnement sont définies dans `.env`
- Configuration Ansible dans `ansible.cfg`
- Bash est installé avec support des alias
- **OpenTofu (dernière version)** est installé - alternative open-source à Terraform

# Deployment Commands
## Déploiement standard

deploy-vms

## Déploiement rapide
deploy-vms-fast

## Personnalisé (7 VMs en parallèle)
orchestrate -e auto_apply=true -e ansible_parallel=7