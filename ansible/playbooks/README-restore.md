# Restauration de base de données Dolibarr

Ce playbook permet de restaurer une base de données Dolibarr ET ses documents depuis des fichiers de sauvegarde.

## Structure des fichiers

Placez vos fichiers de sauvegarde dans :
```
ansible/playbooks/files/
├── mysqldump_xxx.sql.gz        # Backup de la base de données
└── dolibarr_documents_backup.tar.gz  # Backup des documents (optionnel)
```

Formats supportés :
- **Base de données** : `.sql` ou `.sql.gz`
- **Documents** : `.tar.gz`, `.tar.bz2`, `.zip`

## Créer un backup des documents

Sur le serveur Dolibarr existant :

```bash
# Créer une archive des documents
cd /var/www
sudo tar -czf dolibarr_documents_backup.tar.gz dolibarr_documents/

# Ou avec bzip2 (meilleure compression)
sudo tar -cjf dolibarr_documents_backup.tar.bz2 dolibarr_documents/

# Télécharger l'archive localement
scp user@server:/var/www/dolibarr_documents_backup.tar.gz ansible/playbooks/files/
```

## Utilisation

### 1. Copier vos backups

```bash
# Backup de la base de données (obligatoire)
cp /chemin/vers/votre_backup.sql.gz ansible/playbooks/files/

# Backup des documents (optionnel mais recommandé)
cp /chemin/vers/dolibarr_documents_backup.tar.gz ansible/playbooks/files/
```

### 2. Modifier les variables si nécessaire

Éditez `restore-dolibarr-db.yml` :
```yaml
vars:
  dolibarr_db_password: "VotreMotDePasse"
  backup_file: "votre_backup.sql.gz"
  documents_backup_file: "dolibarr_documents_backup.tar.gz"
```

### 3. Exécuter la restauration

```bash
cd ansible
ansible-playbook -i inventory/proxmox/inventory.ini playbooks/restore-dolibarr-db.yml
```

### 4. Avec confirmation (mode interactif)

Le tag `dangerous` permet de demander confirmation avant de supprimer la base :

```bash
ansible-playbook -i inventory/proxmox/inventory.ini playbooks/restore-dolibarr-db.yml --ask-tags
```

## ⚠️ ATTENTION

Ce playbook **SUPPRIME** la base de données existante avant de la restaurer !

Assurez-vous d'avoir :
- ✅ Une sauvegarde de la base actuelle
- ✅ Le bon fichier de restauration
- ✅ Les bons identifiants de base de données

## Vérification post-restauration

```bash
# Se connecter à la VM
ssh ansible@192.168.1.111

# Vérifier les tables
sudo mysql dolibarr -u dolibarr -pSecurePassword123! -e "SHOW TABLES;"

# Compter les enregistrements
sudo mysql dolibarr -u dolibarr -pSecurePassword123! -e "SELECT COUNT(*) FROM llx_user;"
```

## Accès à Dolibarr

Après restauration, accédez à : http://192.168.1.111

Utilisez les identifiants de votre backup.
