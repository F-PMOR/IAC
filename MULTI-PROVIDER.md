# Support Multi-Provider (Proxmox + VMware)

Ce projet supporte maintenant le déploiement de VMs sur deux providers :
- **Proxmox VE** (provider par défaut)
- **VMware vSphere**

## Configuration

### 1. Secrets

Ajoutez les credentials VMware dans `.env.secrets` :

```bash
# VMware vSphere Credentials
VSPHERE_SERVER=vcenter.example.com
VSPHERE_USER=administrator@vsphere.local
VSPHERE_PASSWORD=YourVMwarePassword
VSPHERE_ALLOW_UNVERIFIED_SSL=true
```

### 2. CSV

Ajoutez la colonne `provider` dans `config/vms.csv` :

```csv
name,environment,provider,node,description,cores,memory,disk_size,ip,gateway,mac,tags,ansible_groups,playbooks,...
vm-proxmox-01,prod,proxmox,pve01,VM sur Proxmox,2,4096,50,192.168.1.10,192.168.1.1,BC:24:11:44:BF:01,...
vm-vmware-01,prod,vmware,esxi01,VM sur VMware,2,4096,50,192.168.1.20,192.168.1.1,00:50:56:XX:XX:XX,...
```

**Valeurs possibles pour `provider`** :
- `proxmox` (défaut si non spécifié)
- `vmware`

## Architecture

### Fichiers générés

Le script `deploy-terraform.sh` génère deux fichiers Terraform :

- **`vms-from-config-proxmox.tf`** : VMs Proxmox (filtrées par `provider=proxmox`)
- **`vms-from-config-vmware.tf`** : VMs VMware (filtrées par `provider=vmware`)

### Templates Jinja2

- **`config/vms-terraform.tf.j2`** : Template pour Proxmox
- **`config/vms-vmware.tf.j2`** : Template pour VMware

## Providers Terraform

### Proxmox

**Fichier** : `terraform/provider.tf`

**Variables d'environnement** :
- `PROXMOX_VE_ENDPOINT` (ex: https://pve01.home:8006/)
- `PROXMOX_VE_USERNAME` (ex: root@pam)
- `PROXMOX_VE_PASSWORD`

### VMware

**Fichier** : `terraform/provider-vmware.tf`

**Variables d'environnement** :
- `VSPHERE_SERVER` (ex: vcenter.example.com)
- `VSPHERE_USER` (ex: administrator@vsphere.local)
- `VSPHERE_PASSWORD`

**Variables Terraform supplémentaires** (dans `terraform.tfvars`) :
```hcl
vsphere_datacenter = "Datacenter1"
vsphere_datastore  = "Datastore1"
vsphere_network    = "VM Network"
vsphere_template   = "debian-12-template"
```

## Utilisation

### Déploiement complet (tous providers)

```bash
/root/scripts/deploy-infrastructure.sh
```

### Déploiement Terraform uniquement

```bash
/root/scripts/deploy-terraform.sh --auto-apply
```

Le script va :
1. Lire le CSV avec la colonne `provider`
2. Générer deux fichiers Terraform (un par provider)
3. Initialiser Terraform (télécharge les deux providers)
4. Créer les VMs sur Proxmox ET VMware

### Configuration Ansible

Ansible fonctionne de manière identique pour les deux providers :
- Les playbooks utilisent l'inventaire dynamique basé sur les groupes Ansible
- Peu importe le provider, Ansible se connecte en SSH

## Exemples

### VM Proxmox

```csv
dolibarr-prod01,prod,proxmox,pve01,Dolibarr Production,2,4096,50,192.168.1.101,192.168.1.1,BC:24:11:44:BF:01,"terraform,prod,web","prod,webservers","post-installation.yml,deploy-dolibarr.yml"
```

### VM VMware

```csv
dolibarr-vmware01,prod,vmware,esxi01,Dolibarr sur VMware,2,4096,50,192.168.1.201,192.168.1.1,00:50:56:01:02:03,"terraform,prod,web","prod,webservers","post-installation.yml,deploy-dolibarr.yml"
```

## Configuration VMware

### Prérequis

1. **Template VM** : Créer un template Debian 12 dans vSphere
2. **Réseau** : Configurer un réseau accessible (ex: VM Network)
3. **Datastore** : Avoir un datastore disponible
4. **Permissions** : L'utilisateur doit avoir les droits de création de VM

### Variables dans terraform.tfvars

Créer ou modifier `terraform/terraform.tfvars` :

```hcl
# VMware configuration
vsphere_datacenter           = "Datacenter1"
vsphere_datastore            = "Datastore1"
vsphere_network              = "VM Network"
vsphere_template             = "debian-12-template"
vsphere_allow_unverified_ssl = true
```

## Commandes utiles

### Vérifier les VMs par provider

```bash
# Dans le conteneur
cd /root/config
python3 -c "
import csv
with open('vms.csv') as f:
    reader = csv.DictReader(f)
    proxmox = [r['name'] for r in reader if r.get('provider', 'proxmox') == 'proxmox']
    
with open('vms.csv') as f:
    reader = csv.DictReader(f)
    vmware = [r['name'] for r in reader if r.get('provider') == 'vmware']
    
print(f'Proxmox VMs: {len(proxmox)}')
print(f'VMware VMs: {len(vmware)}')
"
```

### Lister les ressources Terraform

```bash
cd /root/terraform
tofu state list | grep proxmox
tofu state list | grep vsphere
```

### Déployer uniquement Proxmox

Si vous ne voulez pas utiliser VMware, laissez simplement la colonne `provider` à `proxmox` pour toutes les VMs.

## Troubleshooting

### Erreur "provider vmware not found"

**Cause** : Les credentials VMware ne sont pas configurés

**Solution** :
1. Vérifier `.env.secrets` contient `VSPHERE_*`
2. Redémarrer le conteneur : `podman-compose down && podman-compose up -d`

### Erreur "datacenter not found"

**Cause** : La variable `vsphere_datacenter` n'est pas définie

**Solution** : Ajouter dans `terraform/terraform.tfvars` :
```hcl
vsphere_datacenter = "VotreDatacenter"
```

### Les VMs VMware ne se créent pas

**Vérifications** :
1. Le template existe : `vsphere_template = "nom-du-template"`
2. Les permissions de l'utilisateur sont suffisantes
3. Le datastore a assez d'espace

## Migration Proxmox → VMware

Pour migrer une VM de Proxmox vers VMware :

1. Modifier le CSV : changer `proxmox` → `vmware`
2. Adapter le `node` (ex: `pve01` → `esxi01`)
3. Adapter la MAC address si nécessaire
4. Lancer le déploiement

**Note** : Cela créera une nouvelle VM sur VMware, l'ancienne sur Proxmox restera en place.

Pour supprimer l'ancienne :
```bash
/root/scripts/destroy-vms.sh --vm nom-de-la-vm
```

## Performances

- **Proxmox** : Parallélisme = 10 VMs simultanées
- **VMware** : Parallélisme géré par vSphere (généralement 5-8)
- **Total** : Les deux providers peuvent créer en parallèle

## Sécurité

✅ **Bonnes pratiques** :
- Tous les mots de passe dans `.env.secrets`
- Variables Terraform marquées `sensitive = true`
- `.env.secrets` en chmod 600 et ignoré par Git

⚠️ **À faire** :
- Changer les mots de passe par défaut
- Activer le 2FA sur vCenter si possible
- Utiliser des comptes de service dédiés (pas administrator)
