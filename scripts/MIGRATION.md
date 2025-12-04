# Migration vers la nouvelle architecture

## Changements principaux

### Avant (système monolithique)
```bash
# Un seul playbook Ansible qui gère tout
ansible-playbook playbooks/orchestrate-deployment.yml -e auto_apply=true
```

### Après (système modulaire)
```bash
# Script bash orchestrateur qui appelle Terraform puis Ansible
/root/scripts/deploy-infrastructure.sh
```

## Avantages de la nouvelle architecture

1. **Séparation des responsabilités**
   - Terraform : Création/destruction de VMs
   - Ansible : Configuration des VMs
   - Scripts bash : Orchestration et logique de workflow

2. **Flexibilité accrue**
   - Possibilité d'exécuter uniquement Terraform ou Ansible
   - Détection automatique des nouvelles VMs
   - Options multiples pour différents cas d'usage

3. **Meilleure maintenabilité**
   - Code plus simple et plus lisible
   - Debugging facilité (logs séparés)
   - Tests unitaires possibles sur chaque composant

## Correspondance des commandes

### Déploiement complet

**Avant :**
```bash
cd /root/ansible
ansible-playbook playbooks/orchestrate-deployment.yml -e auto_apply=true
```

**Après :**
```bash
/root/scripts/deploy-infrastructure.sh
```

### Plan uniquement

**Avant :**
```bash
cd /root/ansible
ansible-playbook playbooks/orchestrate-deployment.yml
```

**Après :**
```bash
/root/scripts/deploy-infrastructure.sh --plan-only
```

### Déployer uniquement les nouvelles VMs

**Avant :**
```bash
cd /root/ansible
ansible-playbook playbooks/orchestrate-deployment.yml -e auto_apply=true -e skip_existing_vms=true
```

**Après :**
```bash
/root/scripts/deploy-infrastructure.sh --skip-existing
```

### Configurer uniquement avec Ansible

**Avant :**
```bash
# Pas possible directement, fallait commenter les tasks Terraform
```

**Après :**
```bash
/root/scripts/deploy-infrastructure.sh --ansible-only
# ou
/root/scripts/deploy-ansible.sh
```

### Créer uniquement les VMs

**Avant :**
```bash
# Pas possible directement, fallait commenter les tasks Ansible
```

**Après :**
```bash
/root/scripts/deploy-infrastructure.sh --terraform-only
# ou
/root/scripts/deploy-terraform.sh --auto-apply
```

## Fichiers obsolètes

Vous pouvez supprimer ou archiver ces fichiers (mais gardez-les en backup) :

```bash
# Ancien orchestrateur Ansible (remplacé par scripts bash)
ansible/playbooks/orchestrate-deployment.yml

# Si vous voulez le garder en backup
mv /root/ansible/playbooks/orchestrate-deployment.yml \
   /root/ansible/playbooks/orchestrate-deployment.yml.backup
```

## Nouveaux fichiers

```bash
scripts/
├── deploy-infrastructure.sh  # Orchestrateur principal (remplace orchestrate-deployment.yml)
├── deploy-terraform.sh       # Gestion Terraform
├── deploy-ansible.sh         # Gestion Ansible
└── README.md                 # Documentation des scripts

ansible/playbooks/
└── configure-vms.yml         # Playbook Ansible de configuration (remplace la partie Ansible d'orchestrate-deployment.yml)

config/
├── newly-created-vms.txt     # Liste des VMs nouvellement créées (généré automatiquement)
└── vms-terraform.tf.j2       # Template Jinja2 (déplacé depuis ansible/playbooks/templates/)
```

## Migration étape par étape

### 1. Sauvegarder l'existant

```bash
cd /root
tar czf backup-before-migration-$(date +%Y%m%d).tar.gz \
    ansible/playbooks/orchestrate-deployment.yml \
    scripts/
```

### 2. Vérifier la nouvelle architecture

```bash
# Tester avec plan uniquement
/root/scripts/deploy-infrastructure.sh --plan-only

# Vérifier que le plan est correct
cd /root/terraform
tofu show tfplan
```

### 3. Tester sur une VM de dev

```bash
# Modifier vms.csv pour ajouter une VM de test
# Puis déployer uniquement les nouvelles
/root/scripts/deploy-infrastructure.sh --skip-existing
```

### 4. Valider le comportement

```bash
# Tester la configuration Ansible seule
/root/scripts/deploy-ansible.sh --skip-existing

# Vérifier les logs
cd /root/ansible
ansible all -m ping -i inventory/proxmox/inventory.ini
```

### 5. Migration complète

Une fois validé, vous pouvez utiliser exclusivement les nouveaux scripts.

## Rollback en cas de problème

Si vous rencontrez des problèmes avec la nouvelle architecture :

```bash
# Restaurer l'ancien système
cd /root
tar xzf backup-before-migration-YYYYMMDD.tar.gz

# Utiliser l'ancienne commande
cd /root/ansible
ansible-playbook playbooks/orchestrate-deployment.yml -e auto_apply=true
```

## Points d'attention

1. **Template Jinja2** : Le template `vms-terraform.tf.j2` doit être dans `/root/config/` (plus dans ansible/playbooks/templates/)

2. **Fichier newly-created-vms.txt** : Créé automatiquement par le script Terraform, utilisé par Ansible en mode skip_existing

3. **Permissions** : Les scripts bash doivent être exécutables (`chmod +x /root/scripts/*.sh`)

4. **Chemins absolus** : Tous les scripts utilisent des chemins absolus (`/root/...`) pour éviter les problèmes

## Workflow recommandé après migration

### Pour le développement quotidien

```bash
# 1. Modifier config/vms.csv
# 2. Déployer uniquement les nouvelles VMs
/root/scripts/deploy-infrastructure.sh --skip-existing
```

### Pour la production

```bash
# 1. Modifier config/vms.csv
# 2. Vérifier le plan
/root/scripts/deploy-terraform.sh --plan-only

# 3. Review du plan
cd /root/terraform && tofu show tfplan

# 4. Appliquer si OK
/root/scripts/deploy-infrastructure.sh --terraform-only

# 5. Configurer après validation
/root/scripts/deploy-infrastructure.sh --ansible-only
```

## Questions fréquentes

### Puis-je utiliser l'ancien playbook orchestrate-deployment.yml ?

Oui, il reste fonctionnel, mais il n'est plus maintenu. Utilisez les nouveaux scripts pour bénéficier des améliorations.

### Que se passe-t-il si newly-created-vms.txt n'existe pas ?

Le script Ansible considère qu'aucune VM n'a été créée et ignore toutes les VMs en mode `--skip-existing`.

### Comment forcer la reconfiguration d'une VM spécifique ?

```bash
# Option 1: Sans skip-existing
/root/scripts/deploy-ansible.sh

# Option 2: Playbook spécifique
cd /root/ansible
ansible-playbook playbooks/post-installation.yml -l vm-name -i inventory/proxmox/inventory.ini
```

### Les anciennes options Ansible fonctionnent-elles encore ?

Oui :
- `-e auto_apply=true` → `deploy-infrastructure.sh` (sans option)
- `-e skip_existing_vms=true` → `--skip-existing`
- `-e ansible_parallel=5` → `--parallel 5`
