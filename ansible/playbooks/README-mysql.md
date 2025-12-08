# Playbook setup-mysql.yml

## Description

Ce playbook déploie et configure un serveur MySQL/MariaDB complet avec :
- Installation de MariaDB server et client
- Configuration du mot de passe root
- Suppression des utilisateurs anonymes et base test
- Configuration de performance (buffer pool, connections, etc.)
- Création de bases de données
- Création d'utilisateurs avec privilèges
- Configuration firewall

## Utilisation

```bash
# Déploiement sur le groupe databases
ansible-playbook -i inventory/proxmox/inventory.ini playbooks/setup-mysql.yml

# Avec variables custom
ansible-playbook -i inventory/proxmox/inventory.ini playbooks/setup-mysql.yml \
  -e "mysql_max_connections=500" \
  -e "mysql_innodb_buffer_pool_size=4G"

# Avec vault pour les mots de passe
ansible-playbook -i inventory/proxmox/inventory.ini playbooks/setup-mysql.yml \
  --ask-vault-pass
```

## Variables

### Obligatoires (à mettre dans vault)

```yaml
vault_mysql_root_password: "VotreSuperMotDePasseRoot"
vault_dolibarr_db_password: "MotDePasseDolibarr"
```

### Optionnelles

```yaml
mysql_max_connections: 200              # Nombre max de connexions
mysql_innodb_buffer_pool_size: "2G"    # Taille du buffer InnoDB
mysql_bind_address: "0.0.0.0"          # Écoute sur toutes les interfaces
mysql_port: 3306                        # Port MySQL

# Bases de données à créer
mysql_databases:
  - name: dolibarr
    encoding: utf8mb4
    collation: utf8mb4_general_ci
  - name: wordpress
    encoding: utf8mb4
    collation: utf8mb4_unicode_ci

# Utilisateurs à créer
mysql_users:
  - name: dolibarr
    password: "{{ vault_dolibarr_db_password }}"
    priv: "dolibarr.*:ALL"
    host: "%"
  - name: wordpress
    password: "{{ vault_wordpress_db_password }}"
    priv: "wordpress.*:ALL"
    host: "192.168.1.%"
```

## Configuration Vault

Créez un fichier vault pour les secrets :

```bash
# Créer/éditer le vault
ansible-vault create ansible/group_vars/databases/vault.yml

# Ou éditer un existant
ansible-vault edit ansible/group_vars/databases/vault.yml
```

Contenu du vault :

```yaml
---
vault_mysql_root_password: "SuperSecureRootPassword123!"
vault_dolibarr_db_password: "SecurePassword123!"
```

## Templates

### my.cnf.j2
Configuration client MySQL pour root (dans `/root/.my.cnf`)

### mysqld.cnf.j2
Configuration serveur MariaDB avec optimisations :
- Buffer pool InnoDB
- Connexions max
- Logs (error, slow query)
- Character set UTF-8
- Sécurité

## Exemples

### Serveur MySQL dédié

```yaml
# Dans vms.csv ou vms-config.yml
- name: mysql-prod01
  cores: 4
  memory: 8192
  playbooks:
    - name: setup-mysql.yml
      vars:
        mysql_max_connections: 500
        mysql_innodb_buffer_pool_size: "6G"
```

### Serveur avec plusieurs bases

```yaml
mysql_databases:
  - name: dolibarr_prod
  - name: dolibarr_preprod
  - name: wordpress
  - name: nextcloud

mysql_users:
  - name: dolibarr_prod
    password: "{{ vault_dolibarr_prod_password }}"
    priv: "dolibarr_prod.*:ALL"
  - name: dolibarr_preprod
    password: "{{ vault_dolibarr_preprod_password }}"
    priv: "dolibarr_preprod.*:ALL"
```

## Post-installation

### Connexion à MySQL

```bash
# En tant que root (depuis le serveur)
mysql -u root -p

# Ou avec .my.cnf
mysql

# Depuis un autre serveur
mysql -h 192.168.1.110 -u dolibarr -p
```

### Vérifications

```sql
-- Lister les bases
SHOW DATABASES;

-- Lister les utilisateurs
SELECT User, Host FROM mysql.user;

-- Vérifier les privilèges
SHOW GRANTS FOR 'dolibarr'@'%';

-- Vérifier les variables
SHOW VARIABLES LIKE 'max_connections';
SHOW VARIABLES LIKE 'innodb_buffer_pool_size';
```

## Performance

Le playbook configure automatiquement :
- **Buffer pool** : 2G par défaut (ajuster selon RAM disponible)
- **Max connections** : 200 par défaut
- **Query cache** : Désactivé (déprécié dans MariaDB 10.5+)
- **Slow query log** : Activé (requêtes > 2 secondes)

### Recommandations

- Buffer pool = 70-80% de la RAM pour serveur dédié
- Max connections selon le nombre d'applications
- Activer binary logging pour réplication/backup

## Sécurité

✅ Mot de passe root obligatoire
✅ Suppression utilisateurs anonymes
✅ Suppression base de données test
✅ Bind sur interface spécifique possible
✅ Firewall configuré automatiquement
