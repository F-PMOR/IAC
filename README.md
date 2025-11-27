# Ansible Podman Workspace

Conteneur Docker/Podman avec Ansible et OpenTofu pour l'automatisation de l'infrastructure.

## Construction et démarrage

Construire l'image personnalisée avec bash :
```bash
podman-compose build
```

Démarrer le conteneur Ansible :
```bash
podman-compose up -d
```

Ou en une seule commande :
```bash
podman-compose up -d --build
```

## Connexion au conteneur

Se connecter au conteneur pour exécuter vos playbooks (avec bash pour avoir les alias) :
```bash
podman exec -it ansible-workspace /bin/bash
```

## Exécuter un playbook

Une fois connecté dans le conteneur :
```bash
ansible-playbook votre-playbook.yml
```

Ou directement depuis l'hôte :
```bash
podman exec -it ansible-workspace ansible-playbook votre-playbook.yml
```

## Alias disponibles

Les alias Ansible et OpenTofu sont automatiquement chargés dans bash.

**Ansible :**
- `ap` → `ansible-playbook`
- `apc` → `ansible-playbook --check`
- `apd` → `ansible-playbook --diff`
- `aping` → `ansible all -m ping`
- `ave` → `ansible-vault edit`

**OpenTofu (compatible Terraform) :**
- `tf` → `tofu`
- `tfi` → `tofu init`
- `tfp` → `tofu plan`
- `tfa` → `tofu apply`
- `tfd` → `tofu destroy`
- `tfv` → `tofu validate`
- `tff` → `tofu fmt`

Voir le fichier `.bash_aliases` pour la liste complète.

## Arrêt

Arrêter le conteneur :
```bash
podman-compose down
```

## Reconstruction

Si vous modifiez le Dockerfile :
```bash
podman-compose down
podman-compose build --no-cache
podman-compose up -d
```

## Notes

- Vos playbooks du répertoire courant sont montés dans `/ansible/playbooks`
- Les clés SSH de votre système sont montées en lecture seule dans `/root/.ssh`
- Le conteneur reste actif en arrière-plan pour permettre les connexions
- Les variables d'environnement sont définies dans `.env`
- Configuration Ansible dans `ansible.cfg`
- Bash est installé avec support des alias
- **OpenTofu (dernière version)** est installé - alternative open-source à Terraform
