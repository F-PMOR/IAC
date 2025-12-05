#!/bin/bash

###############################################################################
# Script: clean-terraform.sh
# Description: Nettoie les fichiers temporaires et le cache de Terraform
# Usage: ./clean-terraform.sh [options]
###############################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TERRAFORM_DIR="$PROJECT_ROOT/terraform"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Options
CLEAN_STATE=false
CLEAN_PROVIDERS=false
CLEAN_ALL=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --state)
            CLEAN_STATE=true
            shift
            ;;
        --providers)
            CLEAN_PROVIDERS=true
            shift
            ;;
        --all)
            CLEAN_ALL=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --state      Supprimer le fichier d'état Terraform (terraform.tfstate)"
            echo "  --providers  Supprimer les providers téléchargés (.terraform/providers/)"
            echo "  --all        Tout nettoyer (cache, lock, state, providers)"
            echo "  -h, --help   Afficher cette aide"
            echo ""
            echo "Par défaut (sans option):"
            echo "  - Supprime .terraform/ (cache)"
            echo "  - Supprime .terraform.lock.hcl (lock file)"
            echo "  - Supprime tfplan (plan binaire)"
            echo "  - Garde le state et les inventaires générés"
            exit 0
            ;;
        *)
            echo -e "${RED}Option inconnue: $1${NC}"
            exit 1
            ;;
    esac
done

echo "========================================"
echo "    NETTOYAGE TERRAFORM"
echo "========================================"
echo ""

cd "$TERRAFORM_DIR"

# Nettoyage standard
echo -e "${BLUE}🧹 Nettoyage standard...${NC}"

if [ -d ".terraform" ]; then
    if [ "$CLEAN_ALL" = true ] || [ "$CLEAN_PROVIDERS" = false ]; then
        rm -rf .terraform
        echo -e "   ${GREEN}✅${NC} Cache .terraform/ supprimé"
    fi
fi

if [ -f ".terraform.lock.hcl" ]; then
    rm -f .terraform.lock.hcl
    echo -e "   ${GREEN}✅${NC} Lock file supprimé"
fi

if [ -f "tfplan" ]; then
    rm -f tfplan
    echo -e "   ${GREEN}✅${NC} Plan binaire supprimé"
fi

if [ -f "terraform.tfplan" ]; then
    rm -f terraform.tfplan
    echo -e "   ${GREEN}✅${NC} Plan binaire supprimé"
fi

# Nettoyage des fichiers générés par l'ancien système
if [ -f "vms-from-config-proxmox.tf" ]; then
    rm -f vms-from-config-proxmox.tf
    echo -e "   ${GREEN}✅${NC} Fichier obsolète vms-from-config-proxmox.tf supprimé"
fi

if [ -f "vms-from-config-vmware.tf" ]; then
    rm -f vms-from-config-vmware.tf
    echo -e "   ${GREEN}✅${NC} Fichier obsolète vms-from-config-vmware.tf supprimé"
fi

# Nettoyage du state (optionnel)
if [ "$CLEAN_STATE" = true ] || [ "$CLEAN_ALL" = true ]; then
    echo ""
    echo -e "${YELLOW}⚠️  Nettoyage du state Terraform...${NC}"
    
    if [ -f "terraform.tfstate" ]; then
        # Backup du state avant suppression
        if [ ! -d "backups" ]; then
            mkdir -p backups
        fi
        BACKUP_FILE="backups/terraform.tfstate.backup.$(date +%Y%m%d_%H%M%S)"
        cp terraform.tfstate "$BACKUP_FILE"
        echo -e "   ${BLUE}💾${NC} Backup créé: $BACKUP_FILE"
        
        rm -f terraform.tfstate
        echo -e "   ${GREEN}✅${NC} State supprimé"
    fi
    
    if [ -f "terraform.tfstate.backup" ]; then
        rm -f terraform.tfstate.backup
        echo -e "   ${GREEN}✅${NC} State backup supprimé"
    fi
fi

# Nettoyage des providers (optionnel)
if [ "$CLEAN_PROVIDERS" = true ] || [ "$CLEAN_ALL" = true ]; then
    echo ""
    echo -e "${BLUE}🧹 Nettoyage des providers...${NC}"
    
    if [ -d ".terraform/providers" ]; then
        rm -rf .terraform/providers
        echo -e "   ${GREEN}✅${NC} Providers supprimés"
    fi
fi

echo ""
echo -e "${GREEN}✅ Nettoyage terminé !${NC}"
echo ""

# Afficher les recommandations
if [ "$CLEAN_STATE" = true ] || [ "$CLEAN_ALL" = true ]; then
    echo -e "${YELLOW}⚠️  Le state a été supprimé. Vous devrez :${NC}"
    echo "   1. Réimporter les ressources existantes, ou"
    echo "   2. Créer de nouvelles ressources"
    echo ""
fi

if [ "$CLEAN_PROVIDERS" = true ] || [ "$CLEAN_ALL" = true ]; then
    echo -e "${BLUE}💡 Les providers ont été supprimés.${NC}"
    echo "   Exécutez: tofu init"
    echo ""
fi

if [ "$CLEAN_STATE" = false ] && [ "$CLEAN_PROVIDERS" = false ] && [ "$CLEAN_ALL" = false ]; then
    echo -e "${BLUE}💡 Pour réinitialiser Terraform :${NC}"
    echo "   tofu init"
    echo ""
fi
