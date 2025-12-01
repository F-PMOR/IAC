# Répertoire pour les fichiers de backup SQL et documents

Placez vos fichiers de sauvegarde Dolibarr ici.

## Formats supportés

### Base de données
- `*.sql` - Fichiers SQL non compressés
- `*.sql.gz` - Fichiers SQL compressés avec gzip

### Documents
- `*.tar.gz` - Archive tar compressée avec gzip
- `*.tar.bz2` - Archive tar compressée avec bzip2
- `*.zip` - Archive ZIP

## Exemple

```bash
# Copier vos backups ici
cp ~/backups/mysqldump_dolibarr.sql.gz .
cp ~/backups/dolibarr_documents_backup.tar.gz .
```

## Note

Ce répertoire est ignoré par Git (voir `.gitignore`) pour éviter de committer des données sensibles.
