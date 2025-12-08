# Ansible Role: Dolibarr

Ce rôle installe et configure Dolibarr ERP/CRM depuis le dépôt Git officiel avec toutes ses dépendances.

## Prérequis

- Debian 12 (Bookworm) ou Ubuntu 22.04+
- Ansible 2.9+
- Accès root ou sudo

## Variables

Voir `defaults/main.yml` pour toutes les variables configurables.

### Variables principales :

```yaml
dolibarr_version: "20.0.2"
dolibarr_domain: "dolibarr.local"
dolibarr_db_password: "changeme"
```

## Utilisation

### Playbook simple :

```yaml
---
- hosts: webservers
  become: yes
  roles:
    - dolibarr
```

### Playbook avec variables personnalisées :

```yaml
---
- hosts: webservers
  become: yes
  roles:
    - role: dolibarr
      vars:
        dolibarr_version: "20.0.2"
        dolibarr_domain: "erp.example.com"
        dolibarr_db_password: "SecurePassword123!"
        dolibarr_php_memory_limit: "512M"
```

## Collections requises

Installez les collections Ansible nécessaires :

```bash
ansible-galaxy collection install community.mysql
ansible-galaxy collection install community.general
```

## Post-installation

1. Accédez à `http://{{ dolibarr_domain }}`
2. Si le fichier `install.lock` n'existe pas, suivez l'assistant d'installation
3. Utilisez les identifiants de base de données configurés

## Licence

MIT

## Auteur

IAC Proxmox Team
