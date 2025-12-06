# Infrastructure as Code - Proxmox & VMware

Gestion d'infrastructure multi-provider (Proxmox VE, VMware vSphere) avec Terraform/OpenTofu et Ansible.

## 🎯 Architecture

- **Terraform/OpenTofu** : Provisionnement des VMs (création, configuration réseau, disques)
- **Ansible** : Configuration post-déploiement (packages, services, applications)
- **CSV par provider** : Source unique de vérité pour chaque infrastructure (lecture directe avec \`csvdecode()\`)
- **Cloud-init** : Installation automatique des guest agents (QEMU pour Proxmox, open-vm-tools pour VMware)
- **Inventaires auto-générés** : 3 inventaires Ansible créés automatiquement par Terraform

## 📁 Structure du projet

```
├── config/
│   ├── vms-proxmox.csv         # Configuration VMs Proxmox
│   ├── vms-vmware.csv          # Configuration VMs VMware
│   └── README-CSV-PROVIDERS.md # Documentation CSV
├── terraform/
│   ├── provider.tf             # Providers requis (bpg/proxmox, hashicorp/vsphere)
│   ├── vms-proxmox.tf          # Ressources Proxmox (lecture directe CSV)
│   ├── vms-vmware.tf           # Ressources VMware (lecture directe CSV)
│   ├── inventory-global.tf     # Génération inventaires Ansible
│   └── cloudinit/
│       ├── user-config.yaml           # Config utilisateurs (commun)
│       ├── vendor-config-proxmox.yaml # QEMU guest agent
│       └── vendor-config-vmware.yaml  # VMware Tools
├── ansible/
│   ├── inventory/              # Inventaires générés par Terraform
│   │   ├── proxmox/            # VMs Proxmox uniquement
│   │   ├── vmware/             # VMs VMware uniquement
│   │   └── all/                # Toutes les VMs (groupes préfixés)
│   └── playbooks/
│       ├── orchestrate.yml            # Orchestrateur principal
│       ├── install-qemu-agent.yml     # Installation QEMU agent
│       └── install-vmware-tools.yml   # Installation VMware Tools
├── scripts/
│   ├── deploy-terraform.sh     # Déploiement Terraform (lecture directe CSV)
│   ├── deploy-ansible.sh       # Configuration Ansible
│   ├── deploy-infrastructure.sh # Orchestrateur global
│   ├── import-terraform-vms.sh # Import VMs existantes
│   ├── clean-terraform.sh      # Nettoyage cache Terraform
│   ├── destroy-vms.sh          # Destruction VMs
│   └── check-guest-agents.sh   # Vérification agents
└── docs/
    ├── GUIDE-OPERATIONS.md     # Guide opérationnel
    ├── INVENTAIRES-ANSIBLE.md  # Documentation inventaires
    └── SCHEMA-INVENTAIRES.md   # Schéma flux génération
```

## 🚀 Démarrage rapide

### 1. Prérequis

Créer le fichier \`.env.secrets\` avec vos credentials :

```bash
cp .env.secrets.example .env.secrets
chmod 600 .env.secrets
vim .env.secrets
```

Variables requises :
- \`PROXMOX_VE_ENDPOINT\` : URL de l'API Proxmox (ex: https://pve01.home:8006/)
- \`PROXMOX_VE_USERNAME\` : Utilisateur Proxmox (ex: root@pam)
- \`PROXMOX_VE_PASSWORD\` : Mot de passe Proxmox
- \`VSPHERE_SERVER\` : Serveur vCenter (si VMware)
- \`VSPHERE_USER\` : Utilisateur vSphere (si VMware)
- \`VSPHERE_PASSWORD\` : Mot de passe vSphere (si VMware)

### 2. Démarrage du conteneur

```bash
# Construire et démarrer
podman-compose up -d --build

# Se connecter au conteneur (TFA = Terraform + Ansible)
podman exec -it IAC-TFA /bin/bash
```

### 3. Configuration des VMs

Éditer les fichiers CSV selon vos besoins :

**VMs Proxmox :**
```bash
vim config/vms-proxmox.csv
```

**VMs VMware :**
```bash
vim config/vms-vmware.csv
```

Voir \`config/README-CSV-PROVIDERS.md\` pour la structure détaillée.

### 4. Déploiement

**Dans le conteneur :**

```bash
# Vérifier le plan Terraform
./deploy-terraform.sh --plan-only

# Déployer les VMs
./deploy-terraform.sh --auto-apply

# Configurer avec Ansible (inventaire all/ par défaut)
./deploy-ansible.sh

# Ou spécifier un inventaire
./deploy-ansible.sh --inventory proxmox
./deploy-ansible.sh --inventory vmware
```

**Ou tout en une fois :**
```bash
./deploy-infrastructure.sh
```

## 📊 Inventaires Ansible

Terraform génère automatiquement **3 inventaires** lors du déploiement :

| Inventaire | Contenu | Groupes |
|------------|---------|---------|
| \`inventory/proxmox/\` | VMs Proxmox uniquement | \`prod\`, \`mysql\`, \`webservers\`, etc. |
| \`inventory/vmware/\` | VMs VMware uniquement | \`prod\`, \`appservers\`, etc. |
| \`inventory/all/\` | Toutes les VMs | \`proxmox_prod\`, \`vmware_prod\`, \`all_prod\`, etc. |

Voir \`docs/INVENTAIRES-ANSIBLE.md\` pour plus de détails.

## 🔧 Gestion des VMs

### Ajouter une nouvelle VM

1. Ajouter une ligne dans \`config/vms-proxmox.csv\` ou \`config/vms-vmware.csv\`
2. Appliquer les changements :
   ```bash
   ./deploy-terraform.sh --auto-apply
   ./deploy-ansible.sh --limit nouvelle-vm
   ```

### Importer des VMs existantes

```bash
# Importer toutes les VMs Proxmox
./import-terraform-vms.sh --all --provider proxmox

# Importer une VM spécifique
./import-terraform-vms.sh --vm mysql-prod01 --provider proxmox
```

### Supprimer une VM

```bash
# Lister les VMs
./destroy-vms.sh --list

# Voir le plan de destruction
./destroy-vms.sh --vm mysql-prod01 --plan

# Détruire une VM
./destroy-vms.sh --vm mysql-prod01

# Détruire toutes les VMs d'un provider
./destroy-vms.sh --all --provider proxmox
```

## 🔍 Guest Agents

Les guest agents permettent la communication entre l'hyperviseur et les VMs :

- **Proxmox** : QEMU Guest Agent (installé automatiquement via cloud-init)
- **VMware** : open-vm-tools (installé automatiquement via cloud-init)

**Vérification :**
```bash
./check-guest-agents.sh
```

Voir \`ansible/playbooks/README-GUEST-AGENTS.md\` pour plus de détails.

## 🛠️ Scripts disponibles

| Script | Description |
|--------|-------------|
| \`deploy-terraform.sh\` | Déploie l'infrastructure (lit directement les CSV) |
| \`deploy-ansible.sh\` | Configure les VMs avec Ansible |
| \`deploy-infrastructure.sh\` | Orchestrateur global (Terraform + Ansible) |
| \`import-terraform-vms.sh\` | Importe des VMs existantes dans le state |
| \`clean-terraform.sh\` | Nettoie le cache Terraform |
| \`destroy-vms.sh\` | Détruit une ou plusieurs VMs |
| \`check-guest-agents.sh\` | Vérifie l'état des guest agents |

Voir \`scripts/README.md\` pour la documentation détaillée.

## 🐳 Utilisation du conteneur

### Connexion

```bash
podman exec -it IAC-TFA /bin/bash
```

### Alias disponibles

**Ansible :**
- \`ap\` → \`ansible-playbook\`
- \`apc\` → \`ansible-playbook --check\`
- \`apd\` → \`ansible-playbook --diff\`
- \`aping\` → \`ansible all -m ping\`

**OpenTofu/Terraform :**
- \`tf\` → \`tofu\`
- \`tfi\` → \`tofu init\`
- \`tfp\` → \`tofu plan\`
- \`tfa\` → \`tofu apply\`
- \`tfd\` → \`tofu destroy\`
- \`tfv\` → \`tofu validate\`

Voir \`.bash_aliases\` pour la liste complète.

### Volumes montés

- \`./ansible\` → \`/root/ansible\`
- \`./terraform\` → \`/root/terraform\`
- \`./config\` → \`/root/config\`
- \`./scripts\` → \`/root/scripts\`
- \`./.ssh\` → \`/root/.ssh\`

## 📚 Documentation complète

- **[docs/GUIDE-OPERATIONS.md](docs/GUIDE-OPERATIONS.md)** : Opérations quotidiennes, scénarios pratiques
- **[config/README-CSV-PROVIDERS.md](config/README-CSV-PROVIDERS.md)** : Structure et colonnes des CSV
- **[docs/INVENTAIRES-ANSIBLE.md](docs/INVENTAIRES-ANSIBLE.md)** : Génération automatique des inventaires
- **[docs/SCHEMA-INVENTAIRES.md](docs/SCHEMA-INVENTAIRES.md)** : Schéma visuel du flux
- **[ansible/playbooks/README-GUEST-AGENTS.md](ansible/playbooks/README-GUEST-AGENTS.md)** : Installation des agents
- **[scripts/README.md](scripts/README.md)** : Documentation des scripts

## �� Fonctionnalités clés

- ✅ **Multi-provider** : Proxmox et VMware dans la même infrastructure
- ✅ **Lecture directe CSV** : Pas de génération Python/Jinja2, utilisation de \`csvdecode()\`
- ✅ **Inventaires auto-générés** : 3 inventaires créés par Terraform (proxmox/, vmware/, all/)
- ✅ **Cloud-init** : Configuration automatique des VMs et guest agents
- ✅ **Import de VMs existantes** : Gestion de VMs déjà créées
- ✅ **Destruction sécurisée** : Scripts avec confirmations et mode plan
- ✅ **Lifecycle management** : Protection contre la destruction accidentelle
- ✅ **Container Podman** : Environnement reproductible avec OpenTofu + Ansible

## �� Sécurité

- \`.env.secrets\` ne doit **JAMAIS** être commité (déjà dans \`.gitignore\`)
- Permissions recommandées : \`chmod 600 .env.secrets\`
- Les clés SSH sont montées en lecture seule dans le conteneur
- Option \`prevent_destroy\` disponible dans le code Terraform (production)

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
