# Idempotence Terraform

## Problème résolu

Avant : Les VMs étaient **recréées** à chaque `tofu apply` même si aucun changement réel n'était nécessaire.

**Cause** : Terraform détectait des changements dans :
- Les fichiers cloud-init (`user_config_csv`, `vendor_config_csv`)
- Les références au disque (`file_id`)

## Solution

Ajout d'un bloc `lifecycle` dans la ressource VM :

```terraform
lifecycle {
  ignore_changes = [
    initialization[0].user_data_file_id,
    initialization[0].vendor_data_file_id,
    disk[0].file_id
  ]
}
```

## Comportement maintenant

### ✅ Changements qui déclenchent une modification (pas de recréation)
- Ajout/suppression de tags
- Modification de la description
- Changement de CPU/RAM (redémarrage nécessaire)

### ✅ Changements ignorés (pas d'action)
- Modification des fichiers cloud-init
- Changement de l'image disque de référence

### ⚠️ Changements qui déclenchent une recréation
- Changement de nom de VM
- Changement de nœud Proxmox
- Changement d'adresse MAC
- Changement d'IP (dans initialization)

## Tests d'idempotence

```bash
# 1er run : Créer les VMs
orchestrate-apply

# 2ème run : Devrait afficher "No changes"
orchestrate-apply

# Résultat attendu :
# "No changes. Your infrastructure matches the configuration."
```

## Forcer une recréation

Si vous voulez forcer la recréation d'une VM (pour appliquer de nouveaux paramètres cloud-init par exemple) :

```bash
# Supprimer la VM de l'état Terraform
cd /root/terraform
tofu state rm 'proxmox_virtual_environment_vm.vms_csv["dolibarr_dev01"]'

# Relancer le déploiement
tofu apply
```

Ou directement dans Proxmox :
```bash
# Détruire et recréer
tofu destroy -target='proxmox_virtual_environment_vm.vms_csv["dolibarr_dev01"]'
tofu apply
```

## Bonnes pratiques

### Cloud-init
- ✅ Cloud-init s'exécute **seulement au premier boot**
- ✅ Modifications ultérieures du cloud-init **ne s'appliquent pas** aux VMs existantes
- ✅ Utilisez **Ansible** pour modifier les VMs existantes

### Workflow recommandé

1. **Création** : Terraform + Cloud-init
   - Créer la VM
   - Configurer hostname, users, SSH, réseau

2. **Configuration** : Ansible
   - Installer les packages
   - Configurer les services
   - Déployer les applications

3. **Modifications** : Ansible
   - **Ne modifiez PAS** le cloud-init pour les VMs existantes
   - Utilisez Ansible pour tous les changements post-création

## Scénarios courants

### Ajouter un utilisateur à toutes les VMs
❌ **Mauvais** : Modifier user-config.yaml
✅ **Bon** : Créer un playbook Ansible

### Changer le hostname
❌ **Mauvais** : Modifier le CSV et re-apply
✅ **Bon** : Playbook Ansible avec module `hostname`

### Installer un nouveau package
❌ **Mauvais** : Ajouter dans cloud-init
✅ **Bon** : Playbook Ansible

### Créer une nouvelle VM
✅ **Bon** : Ajouter au CSV et orchestrate-apply

### Modifier CPU/RAM d'une VM existante
✅ **Bon** : Modifier le CSV et orchestrate-apply (redémarrage requis)

## Vérifier l'état

```bash
# Voir ce que Terraform veut faire
cd /root/terraform
tofu plan

# Si "No changes" → système idempotent ✅
# Si modifications → vérifier ce qui change
```

## Debug

Si Terraform veut toujours recréer :

```bash
# Voir le plan détaillé
tofu plan -out=tfplan
tofu show tfplan

# Identifier la cause
# Regardez les lignes avec "-/+" (recréation) ou "~" (modification)
```
