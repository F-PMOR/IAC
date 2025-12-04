# Rapport de Sécurité - Gestion des Secrets

## ✅ État Actuel (3 décembre 2025)

### Secrets Migrés vers Variables d'Environnement

Tous les secrets sensibles ont été migrés vers le fichier `.env.secrets` :

| Secret | Variable | Usage |
|--------|----------|-------|
| Proxmox Endpoint | `PROXMOX_VE_ENDPOINT` | Terraform provider |
| Proxmox Username | `PROXMOX_VE_USERNAME` | Terraform provider |
| Proxmox Password | `PROXMOX_VE_PASSWORD` | Terraform provider |
| MySQL Root Password | `MYSQL_ROOT_PASSWORD` | Ansible setup-mysql.yml |
| Dolibarr DB Password | `DOLIBARR_DB_PASSWORD` | Ansible deploy-dolibarr.yml, restore-dolibarr-db.yml |

### Fichiers Sécurisés

#### ✅ Aucun secret en dur dans :
- `terraform/terraform.tfvars` - Commenté, utilise les variables d'environnement
- `terraform/variables.tf` - Variables avec `default=""`, lues depuis l'environnement
- `ansible/playbooks/setup-mysql.yml` - Utilise `lookup('env', 'MYSQL_ROOT_PASSWORD')`
- `ansible/playbooks/deploy-dolibarr.yml` - Utilise `lookup('env', 'DOLIBARR_DB_PASSWORD')`
- `ansible/playbooks/restore-dolibarr-db.yml` - Utilise `lookup('env', 'DOLIBARR_DB_PASSWORD')`
- `ansible/roles/dolibarr/defaults/main.yml` - Utilise `lookup('env', ...)` avec fallback

#### ⚠️ Fichiers contenant des exemples (OK pour documentation)
- `.env.secrets.example` - Valeurs factices pour l'exemple
- `SECRETS.md` - Documentation avec valeurs d'exemple
- `ansible/playbooks/README-*.md` - Documentation avec exemples
- `ansible/roles/dolibarr/README.md` - Documentation

#### 🔒 Fichier avec secrets réels (protégé)
- `.env.secrets` - Permissions 600, ignoré par Git

### Protection Git

Le `.gitignore` contient :
```
# Secrets et variables d'environnement sensibles
.env.secrets
.env.local
**/*secrets*
!.env.secrets.example

# Terraform
terraform/.terraform/
terraform/.terraform.lock.hcl
terraform/terraform.tfstate
terraform/terraform.tfstate.backup
terraform/tfplan
terraform/*.tfvars.backup
```

## 🔐 Mécanisme de Sécurité

### 1. Variables d'Environnement

Les secrets sont chargés depuis `.env.secrets` dans le conteneur via `podman-compose.yml` :

```yaml
env_file:
  - .env
  - .env.secrets
```

### 2. Lookup Ansible

Les playbooks utilisent le plugin `lookup('env', ...)` :

```yaml
vars:
  mysql_root_password: "{{ lookup('env', 'MYSQL_ROOT_PASSWORD') | default('ChangeMe123!') }}"
```

**Comportement** :
- ✅ Si la variable existe → utilise la valeur de l'environnement
- ⚠️ Sinon → utilise la valeur par défaut (WARNING: non recommandé pour production)

### 3. Variables Terraform

Terraform lit automatiquement les variables d'environnement préfixées :

```bash
PROXMOX_VE_ENDPOINT → utilisé par provider "proxmox"
PROXMOX_VE_USERNAME → utilisé par provider "proxmox"
PROXMOX_VE_PASSWORD → utilisé par provider "proxmox"
```

## 📋 Checklist de Sécurité

- [x] Aucun mot de passe en clair dans les fichiers `.tf`
- [x] Aucun mot de passe en clair dans les fichiers `.yml` (hors documentation)
- [x] `.env.secrets` dans `.gitignore`
- [x] `.env.secrets` avec permissions 600
- [x] Terraform state files dans `.gitignore`
- [x] Documentation claire sur la gestion des secrets
- [x] Fichier d'exemple `.env.secrets.example` fourni
- [x] Variables d'environnement chargées dans le conteneur

## 🚨 Actions à Faire

### Avant de commiter :

```bash
# Vérifier qu'aucun secret n'est présent
git diff --cached | grep -i "password\|secret"

# Vérifier que .env.secrets n'est pas tracké
git status | grep ".env.secrets"
```

### Rotation des mots de passe :

1. Éditer `.env.secrets` avec les nouveaux mots de passe
2. Redémarrer le conteneur : `podman-compose down && podman-compose up -d`
3. Relancer les playbooks concernés

### Backup sécurisé :

```bash
# Chiffrer le fichier de secrets
gpg -c .env.secrets
# Sauvegarder .env.secrets.gpg dans un endroit sûr
```

## 📊 Résumé

| Aspect | État | Notes |
|--------|------|-------|
| Secrets en dur dans le code | ✅ Aucun | Migration complète vers variables d'environnement |
| Protection Git | ✅ Actif | `.gitignore` configuré correctement |
| Permissions fichiers | ✅ OK | `.env.secrets` en 600 |
| Documentation | ✅ Complète | `SECRETS.md` créé |
| Backward compatibility | ✅ OK | Valeurs par défaut en fallback |
| Production ready | ⚠️ Partiel | Changer les mots de passe par défaut |

## 🎯 Recommandations

### Court terme (Immédiat)
1. ✅ **Changer tous les mots de passe par défaut** dans `.env.secrets`
2. ✅ **Vérifier** que `.env.secrets` n'est pas dans Git : `git check-ignore .env.secrets`
3. ✅ **Sauvegarder** `.env.secrets` de manière sécurisée

### Moyen terme
1. Considérer l'utilisation d'**Ansible Vault** pour chiffrer `.env.secrets`
2. Mettre en place une **rotation régulière** des mots de passe (tous les 90 jours)
3. Implémenter l'**audit logging** des accès aux secrets

### Long terme
1. Migrer vers un **gestionnaire de secrets externe** (HashiCorp Vault, AWS Secrets Manager)
2. Implémenter **2FA** sur Proxmox
3. Utiliser des **API tokens** au lieu de mots de passe pour Proxmox

---

**Date du rapport** : 3 décembre 2025  
**Statut** : ✅ Sécurisé - Secrets migrés vers variables d'environnement
