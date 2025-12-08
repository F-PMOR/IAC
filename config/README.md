# Configuration centralisée des VMs et déploiements automatisés

## Vue d'ensemble

Ce système permet de gérer toutes vos VMs et leurs configurations depuis un seul fichier YAML central.

## Fichiers

- **`config/vms-config.yml`** : Configuration centralisée (VMs, playbooks, variables)
- **`ansible/playbooks/orchestrate-deployment.yml`** : Orchestrateur principal
- **`ansible/playbooks/tasks/execute-vm-playbooks.yml`** : Tâches d'exécution

## Structure de configuration

```yaml
vms:
  - name: nom-vm
    environment: prod|preprod|dev
    node: pve01
    cores: 2
    memory: 4096
    ip: 192.168.1.x
    
    ansible_groups:
      - groupe1
      - groupe2
    
    playbooks:
      - name: playbook1.yml
        vars:
          var1: value1
      - name: playbook2.yml
        when: condition
```

## Utilisation

### 1. Éditer la configuration

```bash
nano config/vms-config.yml
```

Ajoutez/modifiez vos VMs dans le fichier.

### 2. Déploiement automatique complet

```bash
# Tout déployer automatiquement
ansible-playbook ansible/playbooks/orchestrate-deployment.yml -e auto_apply=true

# Ou en mode plan (sans apply)
ansible-playbook ansible/playbooks/orchestrate-deployment.yml
```

### 3. Déployer seulement certaines VMs

```bash
# Filtrer par environnement
ansible-playbook ansible/playbooks/orchestrate-deployment.yml \
  -e "deploy_filter=prod"

# Filtrer par nom
ansible-playbook ansible/playbooks/orchestrate-deployment.yml \
  -e "vm_names=['dolibarr-prod01','mysql-prod01']"
```

## Workflow complet

```
┌─────────────────────────┐
│  config/vms-config.yml  │  ← Configuration centralisée
└───────────┬─────────────┘
            │
            ↓
┌─────────────────────────┐
│  Génération Terraform   │  ← Création des fichiers .tf
└───────────┬─────────────┘
            │
            ↓
┌─────────────────────────┐
│   Déploiement Terraform │  ← Création des VMs
└───────────┬─────────────┘
            │
            ↓
┌─────────────────────────┐
│  Génération inventaire  │  ← Mise à jour inventory.ini
└───────────┬─────────────┘
            │
            ↓
┌─────────────────────────┐
│  Exécution playbooks    │  ← Configuration des VMs
└─────────────────────────┘
```

## Avantages

✅ **Configuration centralisée** : Un seul fichier à maintenir
✅ **Déploiement automatisé** : De la VM au logiciel déployé
✅ **Réutilisable** : Facile de cloner un environnement
✅ **Versionnable** : Historique Git de tous les changements
✅ **Documenté** : Configuration = documentation

## Exemples

### Ajouter une nouvelle VM

```yaml
- name: monitoring-prod01
  environment: prod
  cores: 2
  memory: 2048
  ip: 192.168.1.130
  mac: "BC:24:11:44:BF:30"
  
  ansible_groups:
    - prod
    - monitoring
  
  playbooks:
    - name: setup-prometheus.yml
    - name: setup-grafana.yml
```

### Déployer un environnement complet

```bash
# 1. Éditer config/vms-config.yml
# 2. Lancer l'orchestrateur
ansible-playbook ansible/playbooks/orchestrate-deployment.yml -e auto_apply=true
```

### Mettre à jour une VM existante

```bash
# Modifier config/vms-config.yml
# Relancer pour appliquer les changements
ansible-playbook ansible/playbooks/orchestrate-deployment.yml -e auto_apply=true
```

## Secrets et variables sensibles

Utilisez Ansible Vault pour les données sensibles :

```yaml
playbooks:
  - name: deploy-app.yml
    vars:
      db_password: "{{ vault_db_password }}"
```

```bash
# Éditer le vault
ansible-vault edit ansible/group_vars/all/vault.yml

# Exécuter avec le vault
ansible-playbook ... --ask-vault-pass
```
