#!/bin/bash

###############################################################################
# Script: erase-terraform-plan.sh
# Description: Supprime tous les fichiers d'état Terraform et fichiers générés
#              pour repartir d'un plan vierge
# Usage: ./scripts/erase-terraform-plan.sh [-f|--force]
###############################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

FORCE_MODE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--force)
            FORCE_MODE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [-f|--force]"
            echo ""
            echo "Supprime l'état Terraform et les fichiers générés pour repartir de zéro."
            echo ""
            echo "Options:"
            echo "  -f, --force    Ne pas demander de confirmation"
            echo "  -h, --help     Afficher cette aide"
            exit 0
            ;;
        *)
            echo -e "${RED}Option inconnue: $1${NC}"
            exit 1
            ;;
    esac
done

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}  Nettoyage de l'état Terraform${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""

# Afficher ce qui sera supprimé
echo "Les fichiers suivants seront supprimés :"
echo ""
echo "  📁 État Terraform:"
echo "     - terraform/terraform.tfstate*"
echo "     - terraform/.terraform.lock.hcl"
echo "     - terraform/.terraform/"
echo ""
echo "  📁 Fichiers générés:"
echo "     - terraform/vms-from-config-proxmox.tf"
echo "     - terraform/vms-from-config-vmware.tf"
echo "     - config/vms-config.yaml"
echo ""
echo "  📁 Inventaire Ansible:"
echo "     - inventory/proxmox/inventory.ini (réinitialisé)"
echo ""

# Demander confirmation sauf si --force
if [ "$FORCE_MODE" = false ]; then
    echo -e "${RED}⚠️  ATTENTION: Cette action est irréversible !${NC}"
    echo -e "${YELLOW}Toutes les VMs devront être réimportées ou recréées.${NC}"
    echo ""
    read -p "Êtes-vous sûr de vouloir continuer ? (oui/non) : " confirmation
    
    if [ "$confirmation" != "oui" ]; then
        echo -e "${YELLOW}❌ Opération annulée${NC}"
        exit 0
    fi
fi

echo ""
echo -e "${GREEN}🗑️  Suppression en cours...${NC}"
echo ""

# Supprimer l'état Terraform
echo "1️⃣  Suppression de l'état Terraform..."
    rm -f /root/terraform/terraform.tfstate* 2>/dev/null || true
    rm -f /root/terraform/.terraform.lock.hcl 2>/dev/null || true
    rm -rf /root/terraform/.terraform/ 2>/dev/null || true


# Supprimer les fichiers générés
echo "2️⃣  Suppression des fichiers générés..."
    rm -f /root/terraform/vms-from-config-proxmox.tf 2>/dev/null || true
    rm -f /root/terraform/vms-from-config-vmware.tf 2>/dev/null || true
    rm -f /root/config/vms-config.yaml 2>/dev/null || true

# Réinitialiser l'inventaire Ansible
echo "3️⃣  Réinitialisation de l'inventaire Ansible..."
    echo '[all]' > /root/ansible/inventory/proxmox/inventory.ini

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ Nettoyage terminé avec succès !${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Prochaines étapes :"
echo ""
echo "1️⃣  Pour RÉIMPORTER les VMs existantes sur Proxmox :"
echo "    ./scripts/import-terraform-vms.sh --all"
echo ""
echo "2️⃣  Pour RECRÉER toute l'infrastructure depuis zéro :"
echo "    - Vérifiez config/vms.csv"
echo "    - Lancez: ./scripts/deploy-terraform.sh -a"
echo ""
echo "3️⃣  Pour importer UNE VM spécifique :"
echo "    ./scripts/import-terraform-vms.sh --vm nom-de-la-vm"
echo ""
