# Configuration des VMs en CSV

## Format du fichier CSV

Le fichier `vms.csv` contient toutes les configurations des VMs dans un format simple à éditer.

### Colonnes

| Colonne | Description | Exemple |
|---------|-------------|---------|
| `name` | Nom de la VM | `dolibarr-prod01` |
| `environment` | Environnement | `prod`, `preprod`, `dev` |
| `node` | Nœud Proxmox | `pve01` |
| `description` | Description | `Dolibarr Production` |
| `cores` | Nombre de cœurs CPU | `2` |
| `memory` | RAM en Mo | `4096` |
| `disk_size` | Taille disque en Go | `50` |
| `ip` | Adresse IP | `192.168.1.101` |
| `gateway` | Passerelle | `192.168.1.1` |
| `mac` | Adresse MAC | `BC:24:11:44:BF:01` |
| `tags` | Tags (séparés par `,`) | `terraform,prod,web` |
| `ansible_groups` | Groupes Ansible (`,`) | `prod,webservers` |
| `playbooks` | Liste de playbooks (`,`) | `deploy.yml,restore.yml` |
| `playbook_vars` | Variables par playbook | Voir format ci-dessous |

### Format des variables de playbooks

Les variables sont organisées ainsi :
- **Entre playbooks** : séparateur `;`
- **Entre variables** : séparateur `|`
- **Clé=valeur** : format `key=value`

**Exemple** :
```
playbooks: deploy.yml,restore.yml
playbook_vars: version=22.0.3|domain=app.com;backup_file=backup.sql.gz
```

Cela signifie :
- `deploy.yml` avec `version=22.0.3` et `domain=app.com`
- `restore.yml` avec `backup_file=backup.sql.gz`

## Utilisation

### 1. Éditer le CSV

Ouvrez `vms.csv` dans Excel, LibreOffice Calc, ou un éditeur de texte :

```bash
# Avec un éditeur
nano config/vms.csv

# Ou dans Excel/Calc pour un tableau
open config/vms.csv
```

### 2. Convertir en YAML

```bash
# Depuis le répertoire racine
python3 config/csv-to-config.py
```

Le script génère automatiquement `config/vms-config.yml`.

### 3. Déployer

```bash
# Déploiement complet
ansible-playbook ansible/playbooks/orchestrate-deployment.yml -e auto_apply=true
```

## Workflow complet

```
┌─────────────┐
│  vms.csv    │  ← Éditer ce fichier (Excel, Calc, nano)
└──────┬──────┘
       │
       ↓ python3 csv-to-config.py
       │
┌──────────────────┐
│ vms-config.yml   │  ← Configuration générée automatiquement
└──────┬───────────┘
       │
       ↓ orchestrate-deployment.yml
       │
┌──────────────────┐
│ Déploiement auto │  ← Terraform + Ansible
└──────────────────┘
```

## Exemples

### Ajouter une VM simple

Ajoutez une ligne dans `vms.csv` :

```csv
nginx-prod01,prod,pve01,Serveur Nginx,2,2048,20,192.168.1.150,192.168.1.1,BC:24:11:44:BF:50,"terraform,prod,web,debian","prod,webservers",setup-nginx.yml,
```

### Ajouter une VM avec plusieurs playbooks

```csv
app-prod01,prod,pve01,Application,4,8192,100,192.168.1.160,192.168.1.1,BC:24:11:44:BF:60,"terraform,prod,app","prod,apps","deploy-app.yml,configure-ssl.yml,setup-monitoring.yml","app_version=2.5.0|domain=app.morry.fr;ssl_email=admin@morry.fr;monitor_port=9090"
```

### Supprimer une VM

1. Supprimez la ligne dans `vms.csv`
2. Régénérez : `python3 config/csv-to-config.py`
3. Supprimez manuellement dans Terraform : `tofu destroy -target=...`

## Avantages du CSV

✅ **Facile à éditer** : Excel, LibreOffice, Google Sheets
✅ **Vue d'ensemble** : Toutes les VMs dans un tableau
✅ **Copier-coller** : Dupliquer facilement des lignes
✅ **Recherche/tri** : Fonctionnalités des tableurs
✅ **Export** : Facile à partager ou importer
✅ **Diff Git** : Changements visibles ligne par ligne

## Conseils

💡 **Backup** : Commitez le CSV avant chaque modification
💡 **Validation** : Le script vérifie la syntaxe à la conversion
💡 **Templates** : Gardez des lignes commentées comme exemples
💡 **Documentation** : La première ligne (entêtes) documente les champs
