# Infrastructure as Code - Proxmox & VMware# Infrastructure as Code - Proxmox & VMware



Gestion d'infrastructure multi-provider (Proxmox VE, VMware vSphere) avec Terraform/OpenTofu et Ansible.Gestion d'infrastructure multi-provider (Proxmox VE, VMware vSphere) avec Terraform/OpenTofu et Ansible.



## 🎯 Architecture## 🎯 Architecture



- **Terraform/OpenTofu** : Provisionnement des VMs (création, configuration réseau, disques)- **Terraform/OpenTofu** : Provisionnement des VMs (création, configuration réseau, disques)

- **Ansible** : Configuration post-déploiement (packages, services, applications)- **Ansible** : Configuration post-déploiement (packages, services, applications)

- **CSV par provider** : Source unique de vérité pour chaque infrastructure (lecture directe avec `csvdecode()`)- **CSV par provider** : Source unique de vérité pour chaque infrastructure

- **Cloud-init** : Installation automatique des guest agents (QEMU pour Proxmox, open-vm-tools pour VMware)- **Cloud-init** : Installation automatique des guest agents (QEMU, VMware Tools)

- **Inventaires auto-générés** : 3 inventaires Ansible créés automatiquement par Terraform

## 📁 Structure du projet

## 📁 Structure du projet

```

```├── config/

├── config/│   ├── vms-proxmox.csv         # Configuration VMs Proxmox

│   ├── vms-proxmox.csv         # Configuration VMs Proxmox│   ├── vms-vmware.csv          # Configuration VMs VMware

│   ├── vms-vmware.csv          # Configuration VMs VMware│   └── README-CSV-PROVIDERS.md # Documentation des CSV

│   └── README-CSV-PROVIDERS.md # Documentation CSV├── terraform/

├── terraform/│   ├── vms-proxmox.tf          # Ressources Terraform Proxmox

│   ├── provider.tf             # Providers requis (bpg/proxmox, hashicorp/vsphere)│   ├── vms-vmware.tf           # Ressources Terraform VMware

│   ├── vms-proxmox.tf          # Ressources Proxmox (lecture directe CSV)│   ├── provider-proxmox.tf     # Configuration provider Proxmox

│   ├── vms-vmware.tf           # Ressources VMware (lecture directe CSV)│   ├── provider-vmware.tf      # Configuration provider VMware

│   ├── inventory-global.tf     # Génération inventaires Ansible│   └── cloudinit/              # Fichiers cloud-init (user/vendor)

│   └── cloudinit/├── ansible/

│       ├── user-config.yaml           # Config utilisateurs (commun)│   ├── inventory/              # Inventaires générés par Terraform

│       ├── vendor-config-proxmox.yaml # QEMU guest agent│   └── playbooks/              # Playbooks de configuration

│       └── vendor-config-vmware.yaml  # VMware Tools│       ├── install-qemu-agent.yml

├── ansible/│       ├── install-vmware-tools.yml

│   ├── inventory/              # Inventaires générés par Terraform│       └── orchestrate.yml

│   │   ├── proxmox/            # VMs Proxmox uniquement└── scripts/

│   │   ├── vmware/             # VMs VMware uniquement    ├── deploy-terraform-v2.sh  # Déploiement Terraform

│   │   └── all/                # Toutes les VMs (groupes préfixés)    ├── deploy-ansible.sh       # Configuration Ansible

│   └── playbooks/    └── check-guest-agents.sh   # Vérification des agents

│       ├── orchestrate.yml            # Orchestrateur principal```

│       ├── install-qemu-agent.yml     # Installation QEMU agent

│       └── install-vmware-tools.yml   # Installation VMware Tools## 🚀 Démarrage rapide

├── scripts/

│   ├── deploy-terraform.sh     # Déploiement Terraform (lecture directe CSV)### 1. Construction et démarrage du conteneur

│   ├── deploy-ansible.sh       # Configuration Ansible

│   ├── deploy-infrastructure.sh # Orchestrateur global

│   ├── import-terraform-vms.sh # Import VMs existantesConstruire l'image personnalisée avec bash :

│   ├── clean-terraform.sh      # Nettoyage cache Terraform```bash

│   ├── destroy-vms.sh          # Destruction VMspodman-compose build

│   └── check-guest-agents.sh   # Vérification agents```

└── docs/

    ├── GUIDE-OPERATIONS.md     # Guide opérationnelDémarrer le conteneur :

    ├── INVENTAIRES-ANSIBLE.md  # Documentation inventaires```bash

    └── SCHEMA-INVENTAIRES.md   # Schéma flux générationpodman-compose up -d

``````



## 🚀 Démarrage rapide### 2. Configuration de l'infrastructure



### 1. PrérequisÉditer les fichiers CSV selon vos besoins :



Créer le fichier `.env.secrets` avec vos credentials :**Pour Proxmox :**

```bash

```bashvim config/vms-proxmox.csv

cp .env.secrets.example .env.secrets```

chmod 600 .env.secrets

vim .env.secrets**Pour VMware :**

``````bash

vim config/vms-vmware.csv

Variables requises :```

- `PROXMOX_VE_ENDPOINT` : URL de l'API Proxmox (ex: https://pve01.home:8006/)

- `PROXMOX_VE_USERNAME` : Utilisateur Proxmox (ex: root@pam)### 3. Déploiement

- `PROXMOX_VE_PASSWORD` : Mot de passe Proxmox

- `VSPHERE_SERVER` : Serveur vCenter (si VMware)**Déployer les VMs avec Terraform :**

- `VSPHERE_USER` : Utilisateur vSphere (si VMware)```bash

- `VSPHERE_PASSWORD` : Mot de passe vSphere (si VMware)# Voir les changements prévus

./scripts/deploy-terraform-v2.sh --plan-only

### 2. Démarrage du conteneur

# Déployer

```bash./scripts/deploy-terraform-v2.sh --auto-apply

# Construire et démarrer```

podman-compose up -d --build

**Configurer les VMs avec Ansible :**

# Se connecter au conteneur```bash

podman exec -it IAC-TFA /bin/bash# Installer les guest agents

```./scripts/deploy-ansible.sh --tags agent



### 3. Configuration des VMs# Configuration complète (Proxmox uniquement par défaut)

./scripts/deploy-ansible.sh

Éditer les fichiers CSV selon vos besoins :

# Configurer toutes les infrastructures

**VMs Proxmox :**INVENTORY_FILE=./ansible/inventory/all/inventory.ini ./scripts/deploy-ansible.sh

```bash

vim config/vms-proxmox.csv# Configurer uniquement VMware

```INVENTORY_FILE=./ansible/inventory/vmware/inventory.ini ./scripts/deploy-ansible.sh

```

**VMs VMware :**

```bash### 4. Inventaires Ansible générés automatiquement

vim config/vms-vmware.csv

```Terraform génère **3 inventaires** lors du `tofu apply` :



Voir `config/README-CSV-PROVIDERS.md` pour la structure détaillée.1. **`inventory/proxmox/inventory.ini`** : VMs Proxmox uniquement

2. **`inventory/vmware/inventory.ini`** : VMs VMware uniquement  

### 4. Déploiement3. **`inventory/all/inventory.ini`** : Toutes les VMs avec groupes par provider



**Dans le conteneur :**Voir [`docs/INVENTAIRES-ANSIBLE.md`](docs/INVENTAIRES-ANSIBLE.md) et [`docs/SCHEMA-INVENTAIRES.md`](docs/SCHEMA-INVENTAIRES.md) pour plus de détails.



```bash## 📋 Gestion des VMs

# Vérifier le plan Terraform

./deploy-terraform.sh --plan-only### Ajouter une nouvelle VM



# Déployer les VMs1. Ajouter une ligne dans le CSV approprié (`vms-proxmox.csv` ou `vms-vmware.csv`)

./deploy-terraform.sh --auto-apply2. Exécuter `./scripts/deploy-terraform-v2.sh --auto-apply`

3. Configurer avec `./scripts/deploy-ansible.sh --limit nouvelle-vm`

# Configurer avec Ansible (inventaire all/ par défaut)

./deploy-ansible.sh### Supprimer une VM



# Ou spécifier un inventaire```bash

./deploy-ansible.sh --inventory proxmoxcd terraform/

./deploy-ansible.sh --inventory vmwaretofu destroy -target='proxmox_virtual_environment_vm.proxmox_vms["vm_name"]'

``````



**Ou tout en une fois :**Puis retirer la ligne du CSV.

```bash

./deploy-infrastructure.sh## 🔧 Guest Agents

```

Les guest agents sont essentiels pour la communication entre l'hyperviseur et les VMs :

## 📊 Inventaires Ansible

- **Proxmox** : QEMU Guest Agent (installé via `cloudinit/vendor-config-proxmox.yaml`)

Terraform génère automatiquement **3 inventaires** lors du déploiement :- **VMware** : VMware Tools / open-vm-tools (installé via `cloudinit/vendor-config-vmware.yaml`)



| Inventaire | Contenu | Groupes |**Installation manuelle :**

|------------|---------|---------|```bash

| `inventory/proxmox/` | VMs Proxmox uniquement | `prod`, `mysql`, `webservers`, etc. |./scripts/deploy-ansible.sh --tags qemu-agent    # Proxmox

| `inventory/vmware/` | VMs VMware uniquement | `prod`, `appservers`, etc. |./scripts/deploy-ansible.sh --tags vmware-tools  # VMware

| `inventory/all/` | Toutes les VMs | `proxmox_prod`, `vmware_prod`, `all_prod`, etc. |./scripts/deploy-ansible.sh --tags agent         # Les deux

```

**Utilisation :**

```bash**Vérification :**

# Toutes les infrastructures```bash

ansible-playbook playbooks/post-installation.yml -i inventory/all/inventory.ini./scripts/check-guest-agents.sh

```

# Uniquement Proxmox

ansible-playbook playbooks/post-installation.yml -i inventory/proxmox/inventory.iniVoir `ansible/playbooks/README-GUEST-AGENTS.md` pour plus de détails.



# Uniquement VMware## 📚 Documentation

ansible-playbook playbooks/post-installation.yml -i inventory/vmware/inventory.ini

- **[docs/GUIDE-OPERATIONS.md](docs/GUIDE-OPERATIONS.md)** : Guide d'exploitation et opérations courantes

# Cibler un groupe spécifique- **[config/README-CSV-PROVIDERS.md](config/README-CSV-PROVIDERS.md)** : Structure et utilisation des fichiers CSV

ansible-playbook playbooks/deploy-app.yml -i inventory/all/inventory.ini --limit proxmox_prod- **[docs/INVENTAIRES-ANSIBLE.md](docs/INVENTAIRES-ANSIBLE.md)** : Génération automatique des inventaires

```- **[docs/SCHEMA-INVENTAIRES.md](docs/SCHEMA-INVENTAIRES.md)** : Schéma du flux de génération

- **[ansible/playbooks/README-GUEST-AGENTS.md](ansible/playbooks/README-GUEST-AGENTS.md)** : Installation des guest agents

Voir `docs/INVENTAIRES-ANSIBLE.md` pour plus de détails.- **[terraform/README.md](terraform/README.md)** : Organisation des fichiers Terraform



## 🔧 Gestion des VMs## 🐳 Utilisation du conteneur



### Ajouter une nouvelle VM### Connexion au conteneur



1. Ajouter une ligne dans `config/vms-proxmox.csv` ou `config/vms-vmware.csv`Se connecter au conteneur pour exécuter vos playbooks (avec bash pour avoir les alias) :

2. Appliquer les changements :```bash

   ```bashpodman exec -it ansible-workspace /bin/bash

   ./deploy-terraform.sh --auto-apply```

   ./deploy-ansible.sh --limit nouvelle-vm

   ```## Exécuter un playbook



### Importer des VMs existantesUne fois connecté dans le conteneur :

```bash

```bashansible-playbook votre-playbook.yml

# Importer toutes les VMs Proxmox```

./import-terraform-vms.sh --all --provider proxmox

Ou directement depuis l'hôte :

# Importer une VM spécifique```bash

./import-terraform-vms.sh --vm mysql-prod01 --provider proxmoxpodman exec -it ansible-workspace ansible-playbook votre-playbook.yml

``````



### Supprimer une VM## Alias disponibles



```bashLes alias Ansible et OpenTofu sont automatiquement chargés dans bash.

# Lister les VMs

./destroy-vms.sh --list**Ansible :**

- `ap` → `ansible-playbook`

# Voir le plan de destruction- `apc` → `ansible-playbook --check`

./destroy-vms.sh --vm mysql-prod01 --plan- `apd` → `ansible-playbook --diff`

- `aping` → `ansible all -m ping`

# Détruire une VM- `ave` → `ansible-vault edit`

./destroy-vms.sh --vm mysql-prod01

**OpenTofu (compatible Terraform) :**

# Détruire toutes les VMs d'un provider- `tf` → `tofu`

./destroy-vms.sh --all --provider proxmox --plan- `tfi` → `tofu init`

./destroy-vms.sh --all --provider proxmox- `tfp` → `tofu plan`

```- `tfa` → `tofu apply`

- `tfd` → `tofu destroy`

Puis supprimer la ligne du CSV et re-générer les inventaires :- `tfv` → `tofu validate`

```bash- `tff` → `tofu fmt`

cd terraform

tofu apply  # Regénère les inventairesVoir le fichier `.bash_aliases` pour la liste complète.

```

## Arrêt

## 🔍 Guest Agents

Arrêter le conteneur :

Les guest agents permettent la communication entre l'hyperviseur et les VMs :```bash

podman-compose down

- **Proxmox** : QEMU Guest Agent (installé automatiquement via cloud-init)```

- **VMware** : open-vm-tools (installé automatiquement via cloud-init)

## Reconstruction

**Vérification :**

```bashSi vous modifiez le Dockerfile :

./check-guest-agents.sh```bash

```podman-compose down

podman-compose build --no-cache

**Installation manuelle si besoin :**podman-compose up -d

```bash```

./deploy-ansible.sh --tags qemu-agent    # Proxmox

./deploy-ansible.sh --tags vmware-tools  # VMware  ## Notes

./deploy-ansible.sh --tags agent         # Les deux

```- Vos playbooks du répertoire courant sont montés dans `/ansible/playbooks`

- Les clés SSH de votre système sont montées en lecture seule dans `/root/.ssh`

Voir `ansible/playbooks/README-GUEST-AGENTS.md` pour plus de détails.- Le conteneur reste actif en arrière-plan pour permettre les connexions

- Les variables d'environnement sont définies dans `.env`

## 🛠️ Scripts disponibles- Configuration Ansible dans `ansible.cfg`

- Bash est installé avec support des alias

| Script | Description |- **OpenTofu (dernière version)** est installé - alternative open-source à Terraform

|--------|-------------|

| `deploy-terraform.sh` | Déploie l'infrastructure (lit directement les CSV) |# Deployment Commands

| `deploy-ansible.sh` | Configure les VMs avec Ansible |## Déploiement standard

| `deploy-infrastructure.sh` | Orchestrateur global (Terraform + Ansible) |

| `import-terraform-vms.sh` | Importe des VMs existantes dans le state |deploy-vms

| `clean-terraform.sh` | Nettoie le cache Terraform |

| `destroy-vms.sh` | Détruit une ou plusieurs VMs |## Déploiement rapide

| `check-guest-agents.sh` | Vérifie l'état des guest agents |deploy-vms-fast



Voir `scripts/README.md` pour la documentation détaillée.## Personnalisé (7 VMs en parallèle)

orchestrate -e auto_apply=true -e ansible_parallel=7
## 🐳 Utilisation du conteneur

### Connexion

```bash
podman exec -it IAC-TFA /bin/bash
```

### Alias disponibles

**Ansible :**
- `ap` → `ansible-playbook`
- `apc` → `ansible-playbook --check`
- `apd` → `ansible-playbook --diff`
- `aping` → `ansible all -m ping`

**OpenTofu/Terraform :**
- `tf` → `tofu`
- `tfi` → `tofu init`
- `tfp` → `tofu plan`
- `tfa` → `tofu apply`
- `tfd` → `tofu destroy`
- `tfv` → `tofu validate`

Voir `.bash_aliases` pour la liste complète.

### Volumes montés

- `./ansible` → `/root/ansible`
- `./terraform` → `/root/terraform`
- `./config` → `/root/config`
- `./scripts` → `/root/scripts`
- `./.ssh` → `/root/.ssh`

### Arrêt et reconstruction

```bash
# Arrêter
podman-compose down

# Reconstruire (si Dockerfile modifié)
podman-compose down
podman-compose build --no-cache
podman-compose up -d
```

## 📚 Documentation complète

- **[docs/GUIDE-OPERATIONS.md](docs/GUIDE-OPERATIONS.md)** : Opérations quotidiennes, scénarios pratiques
- **[config/README-CSV-PROVIDERS.md](config/README-CSV-PROVIDERS.md)** : Structure et colonnes des CSV
- **[docs/INVENTAIRES-ANSIBLE.md](docs/INVENTAIRES-ANSIBLE.md)** : Génération automatique des inventaires
- **[docs/SCHEMA-INVENTAIRES.md](docs/SCHEMA-INVENTAIRES.md)** : Schéma visuel du flux
- **[ansible/playbooks/README-GUEST-AGENTS.md](ansible/playbooks/README-GUEST-AGENTS.md)** : Installation des agents
- **[scripts/README.md](scripts/README.md)** : Documentation des scripts

## 🔑 Fonctionnalités clés

- ✅ **Multi-provider** : Proxmox et VMware dans la même infrastructure
- ✅ **Lecture directe CSV** : Pas de génération Python/Jinja2, utilisation de `csvdecode()`
- ✅ **Inventaires auto-générés** : 3 inventaires créés par Terraform (proxmox/, vmware/, all/)
- ✅ **Cloud-init** : Configuration automatique des VMs et guest agents
- ✅ **Import de VMs existantes** : Gestion de VMs déjà créées
- ✅ **Destruction sécurisée** : Scripts avec confirmations et mode plan
- ✅ **Lifecycle management** : Protection contre la destruction accidentelle
- ✅ **Container Podman** : Environnement reproductible avec OpenTofu + Ansible

## 🔐 Sécurité

- `.env.secrets` ne doit **JAMAIS** être commité (déjà dans `.gitignore`)
- Permissions recommandées : `chmod 600 .env.secrets`
- Les clés SSH sont montées en lecture seule dans le conteneur
- Option `prevent_destroy` disponible dans le code Terraform (production)

## 📝 Versions

- **OpenTofu** : 1.10.7 (compatible Terraform)
- **Ansible** : 2.18+
- **Provider Proxmox** : bpg/proxmox 0.64.0
- **Provider vSphere** : hashicorp/vsphere ~2.6

## 🤝 Contribution

1. Créer une branche feature
2. Tester dans le conteneur
3. Mettre à jour la documentation si nécessaire
4. Créer une pull request

## 📄 Licence

MIT
