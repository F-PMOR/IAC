#!/bin/bash
# Script de déploiement manuel pour une VM
# Usage: ./deploy-vm.sh <vm-name>

VM_NAME="${1:-dolibarr-dev01}"
ANSIBLE_DIR="/root/ansible"

echo "=== Déploiement manuel de $VM_NAME ==="

# Vérifier que la VM est dans l'inventaire
echo "Vérification de l'inventaire..."
ansible-inventory -i ${ANSIBLE_DIR}/inventory/proxmox/inventory.ini --list | grep -q "$VM_NAME"
if [ $? -ne 0 ]; then
    echo "❌ VM $VM_NAME non trouvée dans l'inventaire"
    exit 1
fi

echo "✅ VM trouvée dans l'inventaire"

# Tester la connexion
echo "Test de connexion SSH..."
ansible -i ${ANSIBLE_DIR}/inventory/proxmox/inventory.ini $VM_NAME -m ping
if [ $? -ne 0 ]; then
    echo "❌ Impossible de se connecter à $VM_NAME"
    exit 1
fi

echo "✅ Connexion SSH OK"

# Lancer les playbooks
echo ""
echo "=== Exécution des playbooks ==="

echo "1. Post-installation..."
ansible-playbook -i ${ANSIBLE_DIR}/inventory/proxmox/inventory.ini \
    ${ANSIBLE_DIR}/playbooks/post-installation.yml \
    --limit $VM_NAME

echo ""
echo "2. Déploiement Dolibarr..."
ansible-playbook -i ${ANSIBLE_DIR}/inventory/proxmox/inventory.ini \
    ${ANSIBLE_DIR}/playbooks/deploy-dolibarr.yml \
    --limit $VM_NAME \
    -e "dolibarr_version=22.0.3" \
    -e "dolibarr_domain=dolibarr-dev.morry.fr"

echo ""
echo "=== Déploiement terminé ==="
