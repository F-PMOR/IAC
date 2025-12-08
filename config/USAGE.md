# Commandes rapides - Orchestration IaC

## Configuration

```bash
# Générer la configuration depuis le CSV (de n'importe où)
csv2yaml
# ou
generate-config
```

## Déploiement complet

```bash
# Plan seulement (de n'importe où)
orchestrate

# Plan + Apply automatique (de n'importe où)
orchestrate-apply
# ou
deploy-vms
```

## Workflow complet

```bash
# 1. Éditer le CSV
nano /root/config/vms.csv

# 2. Générer la config
generate-config

# 3. Déployer tout
deploy-vms
```

## Tous les chemins sont absolus

Vous pouvez lancer ces commandes depuis n'importe quel répertoire :
- ✅ `/root`
- ✅ `/root/ansible`
- ✅ `/root/terraform`
- ✅ `/root/ansible/playbooks`
- ✅ N'importe où !

## Variables d'orchestration

```bash
# Sans auto-apply (plan seulement)
orchestrate

# Avec auto-apply (crée les VMs et exécute les playbooks)
orchestrate -e auto_apply=true

# Verbose
orchestrate -e auto_apply=true -vv
```

## Aliases disponibles

| Alias | Commande |
|-------|----------|
| `csv2yaml` | Convertir CSV → YAML |
| `generate-config` | Même chose |
| `orchestrate` | Lancer l'orchestrateur (plan) |
| `orchestrate-apply` | Lancer avec auto-apply |
| `deploy-vms` | Raccourci pour déployer |
| `tf` | OpenTofu |
| `ap` | ansible-playbook |

## Exemples

```bash
# Déployer depuis /root
cd /root
deploy-vms

# Déployer depuis /root/terraform
cd terraform
deploy-vms

# Même résultat partout !
```
