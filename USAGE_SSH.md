# Utilisation de la clé SSH privée


## Méthode 1 : Via variable d'environnement (recommandée)

### Démarrage avec clé SSH à la demande

```bash
# Démarrer le conteneur en passant la clé SSH
SSH_PRIVATE_KEY="$(cat ~/.ssh/votre_cle_privee)" podman-compose up -d

# Ou en une ligne si le conteneur est déjà démarré
podman exec ansible-workspace sh -c 'echo "$(cat ~/.ssh/votre_cle_privee)" > /root/.ssh/id_rsa && chmod 600 /root/.ssh/id_rsa'
```

### Copier-coller manuel

Si vous avez la clé dans le presse-papiers :

```bash
# Démarrer sans clé
podman-compose up -d

# Copier la clé manuellement
podman exec -it ansible-workspace /bin/bash
mkdir -p /root/.ssh
cat > /root/.ssh/id_rsa << 'EOF'
-----BEGIN OPENSSH PRIVATE KEY-----
[COLLER VOTRE CLÉ ICI]
-----END OPENSSH PRIVATE KEY-----
EOF
chmod 600 /root/.ssh/id_rsa
exit
```

## Méthode 2 : Via fichier temporaire

```bash
# Créer un fichier temporaire (ne sera jamais commité)
cat > /tmp/temp_ssh_key << 'EOF'
-----BEGIN OPENSSH PRIVATE KEY-----
[COLLER VOTRE CLÉ ICI]
-----END OPENSSH PRIVATE KEY-----
EOF

# Lancer avec cette clé
SSH_PRIVATE_KEY="$(cat /tmp/temp_ssh_key)" podman-compose up -d

# Supprimer le fichier temporaire
rm /tmp/temp_ssh_key
```

## Méthode 3 : Injection après démarrage

```bash
# Démarrer le conteneur normalement
podman-compose up -d

# Injecter la clé depuis un fichier
podman cp ~/.ssh/votre_cle_privee ansible-workspace:/root/.ssh/id_rsa
podman exec ansible-workspace chmod 600 /root/.ssh/id_rsa
```

## Sécurité

✓ La clé n'est jamais stockée dans le code source
✓ La clé n'est présente que dans le conteneur en cours d'exécution
✓ Aucune trace dans l'historique Git (si vous utilisez la variable d'environnement)
✗ La clé est visible dans les variables d'environnement du processus (considérez Podman secrets pour plus de sécurité)

## Utilisation de Podman Secrets (méthode la plus sécurisée)

```bash
# Créer un secret Podman
podman secret create ssh_private_key ~/.ssh/votre_cle_privee

# Modifier podman-compose.yml pour utiliser le secret
# (nécessite des modifications supplémentaires)
```
