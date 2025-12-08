# Configuration des VMs par CSV

## 📋 Structure

Chaque provider d'infrastructure a son propre fichier CSV :

```
config/
├── vms-proxmox.csv    # VMs sur Proxmox VE
└── vms-vmware.csv     # VMs sur VMware vSphere
```

## 🎯 Avantages de cette organisation

✅ **Clarté** : Chaque infrastructure a ses propres colonnes  
✅ **Indépendance** : Modifiez Proxmox sans toucher VMware  
✅ **Scalabilité** : Ajoutez facilement d'autres providers  
✅ **Simplicité** : Terraform lit directement les CSV avec `csvdecode()`

## 📝 Format des CSV

### vms-proxmox.csv

```csv
name,vmid,environment,node,description,cores,memory,disk_size,ip,gateway,mac,tags,ansible_groups,playbooks,playbook_vars,db_backup_file,documents_backup_file,dolibarr_domain,git_repo_url,git_branch
```

**Colonnes essentielles :**
- `name` : Nom de la VM (unique)
- `vmid` : ID Proxmox (unique, 100-999)
- `node` : Node Proxmox (pve01, pve02, etc.)
- `ip` : Adresse IP statique
- `ansible_groups` : Groupes Ansible séparés par virgules

**Exemple :**
```csv
mysql-prod01,200,prod,pve01,MySQL Production,4,8192,100,192.168.1.100,192.168.1.1,BC:24:11:44:BF:10,"terraform,prod,database","prod,databases","post-installation.yml,setup-mysql.yml",,,,,
```

### vms-vmware.csv

```csv
name,vmid,environment,datacenter,cluster,datastore,description,cores,memory,disk_size,ip,gateway,mac,tags,ansible_groups,playbooks,playbook_vars
```

**Colonnes essentielles :**
- `name` : Nom de la VM (unique)
- `datacenter` : Datacenter vSphere
- `cluster` : Cluster ESXi
- `datastore` : Stockage de la VM
- `ip` : Adresse IP statique
- `ansible_groups` : Groupes Ansible séparés par virgules

**Exemple :**
```csv
app-prod01,1001,prod,DC1,Cluster-Prod,datastore1,Application Production,4,8192,100,192.168.2.100,192.168.2.1,00:50:56:XX:XX:XX,"terraform,prod,app","prod,appservers","post-installation.yml",
```

## 🚀 Workflow

### 1. Ajouter une VM Proxmox

```bash
# Éditer le CSV
vim config/vms-proxmox.csv

# Ajouter une ligne :
nginx-prod01,210,prod,pve01,Nginx LB,2,2048,20,192.168.1.110,192.168.1.1,BC:24:11:44:BF:20,"terraform,prod,web","prod,webservers","post-installation.yml",,,,,,

# Déployer
./scripts/deploy-terraform-v2.sh --auto-apply
```

### 2. Ajouter une VM VMware

```bash
# Éditer le CSV
vim config/vms-vmware.csv

# Ajouter une ligne :
jenkins-prod01,2001,prod,DC-Paris,Prod-Cluster,SSD-DS,Jenkins CI/CD,8,16384,200,192.168.2.101,192.168.2.1,00:50:56:12:34:56,"terraform,prod,ci","prod,ci-servers","post-installation.yml,deploy-jenkins.yml",

# Déployer
./scripts/deploy-terraform-v2.sh --auto-apply
```

### 3. Modifier une VM existante

```bash
# Éditer la ligne correspondante dans le CSV
vim config/vms-proxmox.csv

# Appliquer les changements
cd terraform/
tofu apply
```

### 4. Supprimer une VM

```bash
# Option 1 : Détruire avec Terraform
cd terraform/
tofu destroy -target='proxmox_virtual_environment_vm.proxmox_vms["nom_vm"]'

# Option 2 : Commenter la ligne dans le CSV (préféré pour historique)
# mysql-prod01,200,prod,...

# Puis retirer du state
tofu state rm 'proxmox_virtual_environment_vm.proxmox_vms["mysql_prod01"]'
```

## 🔒 Bonnes pratiques

### Format CSV

✅ **Headers obligatoires** : Toujours conserver la première ligne  
✅ **Guillemets pour virgules** : `"tag1,tag2,tag3"` pour les listes  
✅ **Pas d'espaces** : `192.168.1.100` pas ` 192.168.1.100 `  
✅ **Commentaires** : Préfixer avec `#` : `# mysql-prod01,200,...`

### Gestion des fichiers

```bash
# Toujours faire un backup avant modification
cp vms-proxmox.csv vms-proxmox.csv.backup

# Vérifier la syntaxe CSV
python3 -c "import csv; list(csv.DictReader(open('config/vms-proxmox.csv')))"

# Compter les VMs
tail -n +2 config/vms-proxmox.csv | grep -v "^#" | wc -l
```

### Groupes Ansible

Les groupes dans `ansible_groups` deviennent automatiquement des groupes d'inventaire :

```csv
# ansible_groups = "prod,databases,monitoring"
# Crée les groupes :
#   [prod]
#   [databases]
#   [monitoring]
```

## 📊 Validation

### Vérifier les CSV

```bash
# Proxmox
head config/vms-proxmox.csv
wc -l config/vms-proxmox.csv

# VMware
head config/vms-vmware.csv
grep -v "^#" config/vms-vmware.csv | wc -l
```

### Terraform console

```bash
cd terraform/
tofu console

# Nombre de VMs
> length(local.proxmox_vms)
4
> length(local.vmware_vms)
2

# Détails d'une VM
> local.proxmox_vms["mysql_prod01"]
{
  name = "mysql-prod01"
  ip = "192.168.1.100"
  ...
}

# Sortir
> exit
```

### Dry-run

```bash
# Voir ce qui serait créé/modifié
./scripts/deploy-terraform-v2.sh --plan-only
```

## 🐛 Troubleshooting

### Erreur : "Invalid CSV format"

**Cause** : Virgule manquante ou guillemets mal fermés

**Solution** :
```bash
# Vérifier la syntaxe
python3 -c "import csv; list(csv.DictReader(open('config/vms-proxmox.csv')))"
```

### Erreur : "Duplicate VMID"

**Cause** : Deux VMs avec le même `vmid`

**Solution** :
```bash
# Trouver les doublons
cut -d',' -f2 config/vms-proxmox.csv | sort | uniq -d
```

### Terraform ne voit pas les changements

**Cause** : CSV mal formaté ou Terraform cache

**Solution** :
```bash
cd terraform/
tofu refresh
tofu plan
```

## 📚 Exemples complets

### VM Database Proxmox

```csv
postgres-prod01,204,prod,pve01,PostgreSQL Production,4,8192,100,192.168.1.104,192.168.1.1,BC:24:11:44:BF:14,"terraform,prod,database,postgres","prod,databases","post-installation.yml,setup-postgres.yml",postgres_version=15;,,,,,
```

### VM Application VMware

```csv
webapp-prod01,2010,prod,DC-Paris,Prod-Cluster,SSD-Datastore,Web Application,4,8192,80,192.168.2.110,192.168.2.1,00:50:56:AA:BB:CC,"terraform,prod,web,nodejs","prod,webservers,nodejs","post-installation.yml,deploy-webapp.yml",node_env=production;
```

### VM avec valeurs minimales

```csv
test-dev01,299,dev,pve02,VM de test,2,2048,20,192.168.1.199,192.168.1.1,BC:24:11:44:BF:99,"terraform,dev","dev","post-installation.yml",,,,,,
```

## 🔗 Voir aussi

- [`terraform/vms-proxmox.tf`](../terraform/vms-proxmox.tf) : Lit et crée les VMs Proxmox
- [`terraform/vms-vmware.tf`](../terraform/vms-vmware.tf) : Lit et crée les VMs VMware
- [`scripts/deploy-terraform-v2.sh`](../scripts/deploy-terraform-v2.sh) : Script de déploiement
- [`docs/INVENTAIRES-ANSIBLE.md`](../docs/INVENTAIRES-ANSIBLE.md) : Génération des inventaires
