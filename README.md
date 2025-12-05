# Infrastructure as Code - Proxmox & VMware# Infrastructure as Code - Proxmox & VMware



Gestion d'infrastructure multi-provider (Proxmox VE, VMware vSphere) avec Terraform/OpenTofu et Ansible.



## 🎯 ArchitectureGestion d'infrastructure multi-provider (Proxmox VE, VMware vSphere) avec Terraform/OpenTofu et Ansible.Gestion d'infrastructure multi-provider (Proxmox VE, VMware vSphere) avec Terraform/OpenTofu et Ansible.



- **Terraform/OpenTofu** : Provisionnement des VMs (création, configuration réseau, disques)

- **Ansible** : Configuration post-déploiement (packages, services, applications)

- **CSV par provider** : Source unique de vérité pour chaque infrastructure (lecture directe avec `csvdecode()`)## 🎯 Architecture

- **Cloud-init** : Installation automatique des guest agents (QEMU pour Proxmox, open-vm-tools pour VMware)

- **Inventaires auto-générés** : 3 inventaires Ansible créés automatiquement par Terraform



## 📁 Structure du projet- **Terraform/OpenTofu** : Provisionnement des VMs (création, configuration réseau, disques)- **Terraform/OpenTofu** : Provisionnement des VMs (création, configuration réseau, disques)



```- **Ansible** : Configuration post-déploiement (packages, services, applications)- **Ansible** : Configuration post-déploiement (packages, services, applications)

├── config/

│   ├── vms-proxmox.csv         # Configuration VMs Proxmox- **CSV par provider** : Source unique de vérité pour chaque infrastructure (lecture directe avec `csvdecode()`)- **CSV par provider** : Source unique de vérité pour chaque infrastructure

│   ├── vms-vmware.csv          # Configuration VMs VMware

│   └── README-CSV-PROVIDERS.md # Documentation CSV- **Cloud-init** : Installation automatique des guest agents (QEMU pour Proxmox, open-vm-tools pour VMware)- **Cloud-init** : Installation automatique des guest agents (QEMU, VMware Tools)

├── terraform/

│   ├── provider.tf             # Providers requis (bpg/proxmox, hashicorp/vsphere)- **Inventaires auto-générés** : 3 inventaires Ansible créés automatiquement par Terraform

│   ├── vms-proxmox.tf          # Ressources Proxmox (lecture directe CSV)

│   ├── vms-vmware.tf           # Ressources VMware (lecture directe CSV)## 📁 Structure du projet

│   ├── inventory-global.tf     # Génération inventaires Ansible

│   └── cloudinit/## 📁 Structure du projet

│       ├── user-config.yaml           # Config utilisateurs (commun)

│       ├── vendor-config-proxmox.yaml # QEMU guest agent```

│       └── vendor-config-vmware.yaml  # VMware Tools

├── ansible/```├── config/

│   ├── inventory/              # Inventaires générés par Terraform

│   │   ├── proxmox/            # VMs Proxmox uniquement├── config/│   ├── vms-proxmox.csv         # Configuration VMs Proxmox

│   │   ├── vmware/             # VMs VMware uniquement

│   │   └── all/                # Toutes les VMs (groupes préfixés)│   ├── vms-proxmox.csv         # Configuration VMs Proxmox│   ├── vms-vmware.csv          # Configuration VMs VMware

│   └── playbooks/

│       ├── orchestrate.yml            # Orchestrateur principal│   ├── vms-vmware.csv          # Configuration VMs VMware│   └── README-CSV-PROVIDERS.md # Documentation des CSV

│       ├── install-qemu-agent.yml     # Installation QEMU agent

│       └── install-vmware-tools.yml   # Installation VMware Tools│   └── README-CSV-PROVIDERS.md # Documentation CSV├── terraform/

├── scripts/

│   ├── deploy-terraform.sh     # Déploiement Terraform (lecture directe CSV)├── terraform/│   ├── vms-proxmox.tf          # Ressources Terraform Proxmox

│   ├── deploy-ansible.sh       # Configuration Ansible

│   ├── deploy-infrastructure.sh # Orchestrateur global│   ├── provider.tf             # Providers requis (bpg/proxmox, hashicorp/vsphere)│   ├── vms-vmware.tf           # Ressources Terraform VMware

│   ├── import-terraform-vms.sh # Import VMs existantes

│   ├── clean-terraform.sh      # Nettoyage cache Terraform│   ├── vms-proxmox.tf          # Ressources Proxmox (lecture directe CSV)│   ├── provider-proxmox.tf     # Configuration provider Proxmox

│   ├── destroy-vms.sh          # Destruction VMs

│   └── check-guest-agents.sh   # Vérification agents│   ├── vms-vmware.tf           # Ressources VMware (lecture directe CSV)│   ├── provider-vmware.tf      # Configuration provider VMware

└── docs/

    ├── GUIDE-OPERATIONS.md     # Guide opérationnel│   ├── inventory-global.tf     # Génération inventaires Ansible│   └── cloudinit/              # Fichiers cloud-init (user/vendor)

    ├── INVENTAIRES-ANSIBLE.md  # Documentation inventaires

    └── SCHEMA-INVENTAIRES.md   # Schéma flux génération│   └── cloudinit/├── ansible/

```

│       ├── user-config.yaml           # Config utilisateurs (commun)│   ├── inventory/              # Inventaires générés par Terraform

## 🚀 Démarrage rapide

│       ├── vendor-config-proxmox.yaml # QEMU guest agent│   └── playbooks/              # Playbooks de configuration

### 1. Prérequis

│       └── vendor-config-vmware.yaml  # VMware Tools│       ├── install-qemu-agent.yml

Créer le fichier `.env.secrets` avec vos credentials :

├── ansible/│       ├── install-vmware-tools.yml

```bash

cp .env.secrets.example .env.secrets│   ├── inventory/              # Inventaires générés par Terraform│       └── orchestrate.yml

chmod 600 .env.secrets

vim .env.secrets│   │   ├── proxmox/            # VMs Proxmox uniquement└── scripts/

```

│   │   ├── vmware/             # VMs VMware uniquement    ├── deploy-terraform-v2.sh  # Déploiement Terraform

Variables requises :

- `PROXMOX_VE_ENDPOINT` : URL de l'API Proxmox (ex: https://pve01.home:8006/)│   │   └── all/                # Toutes les VMs (groupes préfixés)    ├── deploy-ansible.sh       # Configuration Ansible

- `PROXMOX_VE_USERNAME` : Utilisateur Proxmox (ex: root@pam)

- `PROXMOX_VE_PASSWORD` : Mot de passe Proxmox│   └── playbooks/    └── check-guest-agents.sh   # Vérification des agents

- `VSPHERE_SERVER` : Serveur vCenter (si VMware)

- `VSPHERE_USER` : Utilisateur vSphere (si VMware)│       ├── orchestrate.yml            # Orchestrateur principal```

- `VSPHERE_PASSWORD` : Mot de passe vSphere (si VMware)

│       ├── install-qemu-agent.yml     # Installation QEMU agent

### 2. Démarrage du conteneur

│       └── install-vmware-tools.yml   # Installation VMware Tools## 🚀 Démarrage rapide

```bash

# Construire et démarrer├── scripts/

podman-compose up -d --build

│   ├── deploy-terraform.sh     # Déploiement Terraform (lecture directe CSV)### 1. Construction et démarrage du conteneur

# Se connecter au conteneur

podman exec -it IAC-TFA /bin/bash│   ├── deploy-ansible.sh       # Configuration Ansible

```

│   ├── deploy-infrastructure.sh # Orchestrateur global

### 3. Configuration des VMs

│   ├── import-terraform-vms.sh # Import VMs existantesConstruire l'image personnalisée avec bash :

Éditer les fichiers CSV selon vos besoins :

│   ├── clean-terraform.sh      # Nettoyage cache Terraform```bash

**VMs Proxmox :**

```bash│   ├── destroy-vms.sh          # Destruction VMspodman-compose build

vim config/vms-proxmox.csv

```│   └── check-guest-agents.sh   # Vérification agents```



**VMs VMware :**└── docs/

```bash

vim config/vms-vmware.csv    ├── GUIDE-OPERATIONS.md     # Guide opérationnelDémarrer le conteneur :

```

    ├── INVENTAIRES-ANSIBLE.md  # Documentation inventaires```bash

Voir `config/README-CSV-PROVIDERS.md` pour la structure détaillée.

    └── SCHEMA-INVENTAIRES.md   # Schéma flux générationpodman-compose up -d

### 4. Déploiement

``````

**Dans le conteneur :**



```bash

# Vérifier le plan Terraform## 🚀 Démarrage rapide### 2. Configuration de l'infrastructure

./deploy-terraform.sh --plan-only



# Déployer les VMs

./deploy-terraform.sh --auto-apply### 1. PrérequisÉditer les fichiers CSV selon vos besoins :



# Configurer avec Ansible (inventaire all/ par défaut)

./deploy-ansible.sh

Créer le fichier `.env.secrets` avec vos credentials :**Pour Proxmox :**

# Ou spécifier un inventaire

./deploy-ansible.sh --inventory proxmox```bash

./deploy-ansible.sh --inventory vmware

``````bashvim config/vms-proxmox.csv



**Ou tout en une fois :**cp .env.secrets.example .env.secrets```

```bash

./deploy-infrastructure.shchmod 600 .env.secrets

```

vim .env.secrets**Pour VMware :**

## 📊 Inventaires Ansible

``````bash

Terraform génère automatiquement **3 inventaires** lors du déploiement :

vim config/vms-vmware.csv

| Inventaire | Contenu | Groupes |

|------------|---------|---------|Variables requises :```

| `inventory/proxmox/` | VMs Proxmox uniquement | `prod`, `mysql`, `webservers`, etc. |

| `inventory/vmware/` | VMs VMware uniquement | `prod`, `appservers`, etc. |- `PROXMOX_VE_ENDPOINT` : URL de l'API Proxmox (ex: https://pve01.home:8006/)

| `inventory/all/` | Toutes les VMs | `proxmox_prod`, `vmware_prod`, `all_prod`, etc. |

- `PROXMOX_VE_USERNAME` : Utilisateur Proxmox (ex: root@pam)### 3. Déploiement

**Utilisation :**

```bash- `PROXMOX_VE_PASSWORD` : Mot de passe Proxmox

# Toutes les infrastructures

ansible-playbook playbooks/post-installation.yml -i inventory/all/inventory.ini- `VSPHERE_SERVER` : Serveur vCenter (si VMware)**Déployer les VMs avec Terraform :**



# Uniquement Proxmox- `VSPHERE_USER` : Utilisateur vSphere (si VMware)```bash

ansible-playbook playbooks/post-installation.yml -i inventory/proxmox/inventory.ini

- `VSPHERE_PASSWORD` : Mot de passe vSphere (si VMware)# Voir les changements prévus

# Uniquement VMware

ansible-playbook playbooks/post-installation.yml -i inventory/vmware/inventory.ini./scripts/deploy-terraform-v2.sh --plan-only



# Cibler un groupe spécifique### 2. Démarrage du conteneur

ansible-playbook playbooks/deploy-app.yml -i inventory/all/inventory.ini --limit proxmox_prod

```# Déployer



Voir `docs/INVENTAIRES-ANSIBLE.md` pour plus de détails.```bash./scripts/deploy-terraform-v2.sh --auto-apply



## 🔧 Gestion des VMs# Construire et démarrer```



### Ajouter une nouvelle VMpodman-compose up -d --build



1. Ajouter une ligne dans `config/vms-proxmox.csv` ou `config/vms-vmware.csv`**Configurer les VMs avec Ansible :**

2. Appliquer les changements :

   ```bash# Se connecter au conteneur```bash

   ./deploy-terraform.sh --auto-apply

   ./deploy-ansible.sh --limit nouvelle-vmpodman exec -it IAC-TFA /bin/bash# Installer les guest agents

   ```

```./scripts/deploy-ansible.sh --tags agent

### Importer des VMs existantes



```bash

# Importer toutes les VMs Proxmox### 3. Configuration des VMs# Configuration complète (Proxmox uniquement par défaut)

./import-terraform-vms.sh --all --provider proxmox

./scripts/deploy-ansible.sh

# Importer une VM spécifique

./import-terraform-vms.sh --vm mysql-prod01 --provider proxmoxÉditer les fichiers CSV selon vos besoins :

```

# Configurer toutes les infrastructures

### Supprimer une VM

**VMs Proxmox :**INVENTORY_FILE=./ansible/inventory/all/inventory.ini ./scripts/deploy-ansible.sh

```bash

# Lister les VMs```bash

./destroy-vms.sh --list

vim config/vms-proxmox.csv# Configurer uniquement VMware

# Voir le plan de destruction

./destroy-vms.sh --vm mysql-prod01 --plan```INVENTORY_FILE=./ansible/inventory/vmware/inventory.ini ./scripts/deploy-ansible.sh



# Détruire une VM```

./destroy-vms.sh --vm mysql-prod01

**VMs VMware :**

# Détruire toutes les VMs d'un provider

./destroy-vms.sh --all --provider proxmox --plan```bash### 4. Inventaires Ansible générés automatiquement

./destroy-vms.sh --all --provider proxmox

```vim config/vms-vmware.csv



Puis supprimer la ligne du CSV et re-générer les inventaires :```Terraform génère **3 inventaires** lors du `tofu apply` :

```bash

cd terraform

tofu apply  # Regénère les inventaires

```Voir `config/README-CSV-PROVIDERS.md` pour la structure détaillée.1. **`inventory/proxmox/inventory.ini`** : VMs Proxmox uniquement



## 🔍 Guest Agents2. **`inventory/vmware/inventory.ini`** : VMs VMware uniquement  



Les guest agents permettent la communication entre l'hyperviseur et les VMs :### 4. Déploiement3. **`inventory/all/inventory.ini`** : Toutes les VMs avec groupes par provider



- **Proxmox** : QEMU Guest Agent (installé automatiquement via cloud-init)

- **VMware** : open-vm-tools (installé automatiquement via cloud-init)

**Dans le conteneur :**Voir [`docs/INVENTAIRES-ANSIBLE.md`](docs/INVENTAIRES-ANSIBLE.md) et [`docs/SCHEMA-INVENTAIRES.md`](docs/SCHEMA-INVENTAIRES.md) pour plus de détails.

**Vérification :**

```bash

./check-guest-agents.sh

``````bash## 📋 Gestion des VMs



**Installation manuelle si besoin :**# Vérifier le plan Terraform

```bash

./deploy-ansible.sh --tags qemu-agent    # Proxmox./deploy-terraform.sh --plan-only### Ajouter une nouvelle VM

./deploy-ansible.sh --tags vmware-tools  # VMware  

./deploy-ansible.sh --tags agent         # Les deux

```

# Déployer les VMs1. Ajouter une ligne dans le CSV approprié (`vms-proxmox.csv` ou `vms-vmware.csv`)

Voir `ansible/playbooks/README-GUEST-AGENTS.md` pour plus de détails.

./deploy-terraform.sh --auto-apply2. Exécuter `./scripts/deploy-terraform-v2.sh --auto-apply`

## 🛠️ Scripts disponibles

3. Configurer avec `./scripts/deploy-ansible.sh --limit nouvelle-vm`

| Script | Description |

|--------|-------------|# Configurer avec Ansible (inventaire all/ par défaut)

| `deploy-terraform.sh` | Déploie l'infrastructure (lit directement les CSV) |

| `deploy-ansible.sh` | Configure les VMs avec Ansible |./deploy-ansible.sh### Supprimer une VM

| `deploy-infrastructure.sh` | Orchestrateur global (Terraform + Ansible) |

| `import-terraform-vms.sh` | Importe des VMs existantes dans le state |

| `clean-terraform.sh` | Nettoie le cache Terraform |

| `destroy-vms.sh` | Détruit une ou plusieurs VMs |# Ou spécifier un inventaire```bash

| `check-guest-agents.sh` | Vérifie l'état des guest agents |

./deploy-ansible.sh --inventory proxmoxcd terraform/

Voir `scripts/README.md` pour la documentation détaillée.

./deploy-ansible.sh --inventory vmwaretofu destroy -target='proxmox_virtual_environment_vm.proxmox_vms["vm_name"]'

## 🐳 Utilisation du conteneur

``````

### Connexion



```bash

podman exec -it IAC-TFA /bin/bash**Ou tout en une fois :**Puis retirer la ligne du CSV.

```

```bash

### Alias disponibles

./deploy-infrastructure.sh## 🔧 Guest Agents

**Ansible :**

- `ap` → `ansible-playbook````

- `apc` → `ansible-playbook --check`

- `apd` → `ansible-playbook --diff`Les guest agents sont essentiels pour la communication entre l'hyperviseur et les VMs :

- `aping` → `ansible all -m ping`

## 📊 Inventaires Ansible

**OpenTofu/Terraform :**

- `tf` → `tofu`- **Proxmox** : QEMU Guest Agent (installé via `cloudinit/vendor-config-proxmox.yaml`)

- `tfi` → `tofu init`

- `tfp` → `tofu plan`Terraform génère automatiquement **3 inventaires** lors du déploiement :- **VMware** : VMware Tools / open-vm-tools (installé via `cloudinit/vendor-config-vmware.yaml`)

- `tfa` → `tofu apply`

- `tfd` → `tofu destroy`

- `tfv` → `tofu validate`

| Inventaire | Contenu | Groupes |**Installation manuelle :**

Voir `.bash_aliases` pour la liste complète.

|------------|---------|---------|```bash

### Volumes montés

| `inventory/proxmox/` | VMs Proxmox uniquement | `prod`, `mysql`, `webservers`, etc. |./scripts/deploy-ansible.sh --tags qemu-agent    # Proxmox

- `./ansible` → `/root/ansible`

- `./terraform` → `/root/terraform`| `inventory/vmware/` | VMs VMware uniquement | `prod`, `appservers`, etc. |./scripts/deploy-ansible.sh --tags vmware-tools  # VMware

- `./config` → `/root/config`

- `./scripts` → `/root/scripts`| `inventory/all/` | Toutes les VMs | `proxmox_prod`, `vmware_prod`, `all_prod`, etc. |./scripts/deploy-ansible.sh --tags agent         # Les deux

- `./.ssh` → `/root/.ssh`

```

### Arrêt et reconstruction

**Utilisation :**

```bash

# Arrêter```bash**Vérification :**

podman-compose down

# Toutes les infrastructures```bash

# Reconstruire (si Dockerfile modifié)

podman-compose downansible-playbook playbooks/post-installation.yml -i inventory/all/inventory.ini./scripts/check-guest-agents.sh

podman-compose build --no-cache

podman-compose up -d```

```

# Uniquement Proxmox

## 📚 Documentation complète

ansible-playbook playbooks/post-installation.yml -i inventory/proxmox/inventory.iniVoir `ansible/playbooks/README-GUEST-AGENTS.md` pour plus de détails.

- **[docs/GUIDE-OPERATIONS.md](docs/GUIDE-OPERATIONS.md)** : Opérations quotidiennes, scénarios pratiques

- **[config/README-CSV-PROVIDERS.md](config/README-CSV-PROVIDERS.md)** : Structure et colonnes des CSV

- **[docs/INVENTAIRES-ANSIBLE.md](docs/INVENTAIRES-ANSIBLE.md)** : Génération automatique des inventaires

- **[docs/SCHEMA-INVENTAIRES.md](docs/SCHEMA-INVENTAIRES.md)** : Schéma visuel du flux# Uniquement VMware## 📚 Documentation

- **[ansible/playbooks/README-GUEST-AGENTS.md](ansible/playbooks/README-GUEST-AGENTS.md)** : Installation des agents

- **[scripts/README.md](scripts/README.md)** : Documentation des scriptsansible-playbook playbooks/post-installation.yml -i inventory/vmware/inventory.ini



## 🔑 Fonctionnalités clés- **[docs/GUIDE-OPERATIONS.md](docs/GUIDE-OPERATIONS.md)** : Guide d'exploitation et opérations courantes



- ✅ **Multi-provider** : Proxmox et VMware dans la même infrastructure# Cibler un groupe spécifique- **[config/README-CSV-PROVIDERS.md](config/README-CSV-PROVIDERS.md)** : Structure et utilisation des fichiers CSV

- ✅ **Lecture directe CSV** : Pas de génération Python/Jinja2, utilisation de `csvdecode()`

- ✅ **Inventaires auto-générés** : 3 inventaires créés par Terraform (proxmox/, vmware/, all/)ansible-playbook playbooks/deploy-app.yml -i inventory/all/inventory.ini --limit proxmox_prod- **[docs/INVENTAIRES-ANSIBLE.md](docs/INVENTAIRES-ANSIBLE.md)** : Génération automatique des inventaires

- ✅ **Cloud-init** : Configuration automatique des VMs et guest agents

- ✅ **Import de VMs existantes** : Gestion de VMs déjà créées```- **[docs/SCHEMA-INVENTAIRES.md](docs/SCHEMA-INVENTAIRES.md)** : Schéma du flux de génération

- ✅ **Destruction sécurisée** : Scripts avec confirmations et mode plan

- ✅ **Lifecycle management** : Protection contre la destruction accidentelle- **[ansible/playbooks/README-GUEST-AGENTS.md](ansible/playbooks/README-GUEST-AGENTS.md)** : Installation des guest agents

- ✅ **Container Podman** : Environnement reproductible avec OpenTofu + Ansible

Voir `docs/INVENTAIRES-ANSIBLE.md` pour plus de détails.- **[terraform/README.md](terraform/README.md)** : Organisation des fichiers Terraform

## 🔐 Sécurité



- `.env.secrets` ne doit **JAMAIS** être commité (déjà dans `.gitignore`)

- Permissions recommandées : `chmod 600 .env.secrets`## 🔧 Gestion des VMs## 🐳 Utilisation du conteneur

- Les clés SSH sont montées en lecture seule dans le conteneur

- Option `prevent_destroy` disponible dans le code Terraform (production)



## 📝 Versions### Ajouter une nouvelle VM### Connexion au conteneur



- **OpenTofu** : 1.10.7 (compatible Terraform)

- **Ansible** : 2.18+

- **Provider Proxmox** : bpg/proxmox 0.64.01. Ajouter une ligne dans `config/vms-proxmox.csv` ou `config/vms-vmware.csv`Se connecter au conteneur pour exécuter vos playbooks (avec bash pour avoir les alias) :

- **Provider vSphere** : hashicorp/vsphere ~2.6

2. Appliquer les changements :```bash

## 🤝 Contribution

   ```bashpodman exec -it ansible-workspace /bin/bash

1. Créer une branche feature

2. Tester dans le conteneur   ./deploy-terraform.sh --auto-apply```

3. Mettre à jour la documentation si nécessaire

4. Créer une pull request   ./deploy-ansible.sh --limit nouvelle-vm



## 📄 Licence   ```## Exécuter un playbook



MIT


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
