#!/bin/bash
# Script d'initialisation

# Configuration de la clé SSH si fournie via variable d'environnement
if [ -n "$SSH_PRIVATE_KEY" ]; then
    echo "Configuration de la clé SSH privée..."
    mkdir -p /root/.ssh
    echo "$SSH_PRIVATE_KEY" > /root/.ssh/id_rsa
    chmod 600 /root/.ssh/id_rsa
    echo "✓ Clé SSH configurée"
fi

# Lance la commande par défaut
exec "$@"
