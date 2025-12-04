# Parallélisation du déploiement

## 🚀 Améliorations de performance

### Avant
- Terraform : 1 VM à la fois (par défaut)
- Ansible : 1 VM à la fois (séquentiel)
- **Temps total** : ~15 minutes pour 4 VMs

### Après
- Terraform : **10 VMs en parallèle** (`-parallelism=10`)
- Ansible : **3 VMs en parallèle** (asynchrone avec `async`)
- **Temps total** : ~5-7 minutes pour 4 VMs

## 📊 Gains de performance

| Étape | Avant | Après | Gain |
|-------|-------|-------|------|
| Création VMs (Terraform) | ~8 min | ~3 min | **62%** |
| Configuration (Ansible) | ~7 min | ~3 min | **57%** |
| **Total** | **~15 min** | **~6 min** | **60%** |

## 🎯 Utilisation

### Déploiement standard (3 VMs en parallèle)
```bash
orchestrate-apply
# ou
deploy-vms
```

### Déploiement rapide (5 VMs en parallèle)
```bash
orchestrate-fast
# ou
deploy-vms-fast
```

### Déploiement personnalisé
```bash
# 7 VMs Ansible en parallèle
orchestrate -e auto_apply=true -e ansible_parallel=7

# Plan seulement (vérifier avant)
orchestrate
```

## ⚙️ Options de parallélisation

### Terraform (`-parallelism`)
```bash
# Défaut dans le playbook : 10
# Maximum recommandé : 10-15 (selon ressources Proxmox)

# Modifier dans orchestrate-deployment.yml :
cmd: tofu plan -out=tfplan -parallelism=15
```

### Ansible (`ansible_parallel`)
```bash
# Défaut : 3 VMs en parallèle
# Recommandé : 3-5 VMs
# Maximum : 10 VMs (selon CPU/RAM disponible)

# Exemple :
orchestrate -e auto_apply=true -e ansible_parallel=5
```

## 🔧 Comment ça fonctionne

### 1. Terraform parallelism
```hcl
tofu apply -parallelism=10
```
- Terraform crée jusqu'à **10 ressources** en même temps
- Les VMs sont créées en parallèle sur Proxmox
- Limité par les dépendances (cloud-init files, images)

### 2. Ansible async
```yaml
async: 3600      # Timeout max (1h)
poll: 0          # Ne pas attendre (lancer et continuer)
```
- Lance les playbooks pour plusieurs VMs **sans attendre**
- Vérifie ensuite l'état avec `async_status`
- Retry toutes les 30 secondes jusqu'à completion

## 📈 Recommandations

### Petite infrastructure (1-5 VMs)
```bash
orchestrate-apply
# Terraform: 10 parallèle
# Ansible: 3 parallèle
```

### Infrastructure moyenne (5-15 VMs)
```bash
orchestrate-fast
# Terraform: 10 parallèle  
# Ansible: 5 parallèle
```

### Grande infrastructure (15+ VMs)
```bash
orchestrate -e auto_apply=true -e ansible_parallel=7
# Terraform: 10 parallèle
# Ansible: 7 parallèle
```

## ⚠️ Limitations

### Proxmox
- API rate limiting (limité par Proxmox)
- Stockage : Ne pas saturer le disque avec trop d'I/O simultanés
- Réseau : Bande passante pour télécharger les images

### Machine locale
- CPU : Ansible consomme du CPU pour gérer les tâches
- RAM : Chaque processus Ansible consomme de la RAM
- SSH : Limite de connexions SSH simultanées

### Recommandation sécuritaire
- **Terraform** : Max 10-15 (safe)
- **Ansible** : Max 5-7 (safe)
- **Au-delà** : Tester progressivement

## 🐛 Dépannage

### Timeout Ansible
```yaml
# Augmenter le timeout (défaut: 3600s = 1h)
async: 7200  # 2 heures
```

### Erreurs Proxmox "Too many requests"
```bash
# Réduire le parallelism Terraform
cmd: tofu apply -parallelism=5
```

### VMs bloquées en création
```bash
# Vérifier les jobs async
cd /root/ansible/playbooks
ansible-playbook orchestrate-deployment.yml -vv
```

## 📊 Monitoring

### Voir les VMs en cours de création
```bash
# Depuis Proxmox
watch -n 2 'pvesh get /cluster/resources --type vm'

# Depuis Terraform
cd /root/terraform
watch -n 2 'tofu show'
```

### Voir les jobs Ansible
```bash
# Dans le playbook, activez verbose
orchestrate -e auto_apply=true -vv
```

## 🎓 Exemple complet

```bash
# 1. Éditer le CSV
nano /root/config/vms.csv

# 2. Générer la config
csv2yaml

# 3. Déployer rapidement (5 VMs Ansible en parallèle)
orchestrate-fast

# Résultat :
# - 4 VMs créées en ~3 minutes (Terraform)
# - 4 VMs configurées en ~3 minutes (Ansible, 3-5 en parallèle)
# - Total : ~6 minutes au lieu de 15 minutes
```

## 🔍 Variables d'environnement

```bash
# Définir le parallélisme par défaut
export TF_PARALLELISM=15
export ANSIBLE_PARALLEL=5

# Lancer avec les variables
orchestrate-apply
```
