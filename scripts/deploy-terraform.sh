#!/bin/bash

###############################################################################
# Script: deploy-terraform-v2.sh
# Description: Déploie l'infrastructure Terraform avec CSV par provider
# Usage: ./scripts/deploy-terraform-v2.sh [--plan-only|--auto-apply]
###############################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Chemins
CONFIG_DIR="${PROJECT_ROOT}/config"
TERRAFORM_DIR="${PROJECT_ROOT}/terraform"
CSV_PROXMOX="${CONFIG_DIR}/vms-proxmox.csv"
CSV_VMWARE="${CONFIG_DIR}/vms-vmware.csv"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Options
PLAN_ONLY=false
AUTO_APPLY=false
NO_REFRESH=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--plan-only)
            PLAN_ONLY=true
            shift
            ;;
        -a|--auto-apply)
            AUTO_APPLY=true
            shift
            ;;
        --no-refresh)
            NO_REFRESH=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Déploie l'infrastructure Terraform depuis les fichiers CSV"
            echo ""
            echo "Options:"
            echo "  -p, --plan-only    Générer le plan uniquement (pas d'apply)"
            echo "  -a, --auto-apply   Appliquer automatiquement sans confirmation"
            echo "  --no-refresh       Ne pas rafraîchir l'état (évite les timeouts)"
            echo "  -h, --help         Afficher cette aide"
            echo ""
            echo "Fichiers CSV utilisés:"
            echo "  - config/vms-proxmox.csv : VMs Proxmox"
            echo "  - config/vms-vmware.csv  : VMs VMware"
            echo ""
            echo "Exemples:"
            echo "  $0 --plan-only          # Voir les changements prévus"
            echo "  $0 --auto-apply         # Déployer automatiquement"
            echo "  $0 --no-refresh -a      # Déployer sans refresh (rapide)"
            exit 0
            ;;
        *)
            echo -e "${RED}Option inconnue: $1${NC}"
            exit 1
            ;;
    esac
done

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}      DÉPLOIEMENT TERRAFORM${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Vérification des fichiers CSV
echo -e "${BLUE}📋 Vérification des fichiers CSV...${NC}"

if [ ! -f "$CSV_PROXMOX" ]; then
    echo -e "${YELLOW}⚠️  Fichier Proxmox non trouvé: $CSV_PROXMOX${NC}"
    PROXMOX_COUNT=0
else
    PROXMOX_COUNT=$(($(wc -l < "$CSV_PROXMOX") - 1))
    echo -e "   ✅ Proxmox : ${GREEN}${PROXMOX_COUNT} VM(s)${NC}"
fi

if [ ! -f "$CSV_VMWARE" ]; then
    echo -e "${YELLOW}⚠️  Fichier VMware non trouvé: $CSV_VMWARE${NC}"
    VMWARE_COUNT=0
else
    # Compter les lignes non commentées
    VMWARE_COUNT=$(grep -v "^#" "$CSV_VMWARE" | grep -v "^$" | tail -n +2 | wc -l | tr -d ' ')
    echo -e "   ✅ VMware  : ${GREEN}${VMWARE_COUNT} VM(s)${NC}"
fi

TOTAL_COUNT=$((PROXMOX_COUNT + VMWARE_COUNT))
echo -e "   ${CYAN}Total    : ${TOTAL_COUNT} VM(s) configurées${NC}"
echo ""

if [ $TOTAL_COUNT -eq 0 ]; then
    echo -e "${RED}❌ Aucune VM configurée dans les fichiers CSV${NC}"
    exit 1
fi

# Vérification des fichiers Terraform
echo -e "${BLUE}🔧 Vérification de la configuration Terraform...${NC}"

if [ ! -f "$TERRAFORM_DIR/vms-proxmox.tf" ]; then
    echo -e "${RED}❌ Fichier manquant: terraform/vms-proxmox.tf${NC}"
    exit 1
fi

if [ ! -f "$TERRAFORM_DIR/vms-vmware.tf" ]; then
    echo -e "${YELLOW}⚠️  Fichier manquant: terraform/vms-vmware.tf (normal si pas de VMware)${NC}"
fi

echo -e "   ✅ Configuration Terraform OK"
echo ""

# Initialisation Terraform
echo -e "${BLUE}🔧 Initialisation de Terraform...${NC}"
cd "$TERRAFORM_DIR"

if [ ! -d ".terraform" ]; then
    tofu init
    echo -e "   ${GREEN}✅ Terraform initialisé${NC}"
else
    echo -e "   ${CYAN}⏭️  Terraform déjà initialisé${NC}"
fi
echo ""

# Validation
echo -e "${BLUE}✓ Validation de la configuration...${NC}"
tofu validate > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo -e "   ${GREEN}✅ Configuration valide${NC}"
else
    echo -e "   ${RED}❌ Configuration invalide${NC}"
    tofu validate
    exit 1
fi
echo ""

# Plan Terraform
echo -e "${BLUE}📋 Génération du plan Terraform...${NC}"

PLAN_CMD="tofu plan"
if [ "$NO_REFRESH" = true ]; then
    PLAN_CMD="$PLAN_CMD -refresh=false"
    echo -e "   ${YELLOW}⚡ Mode sans refresh (rapide)${NC}"
fi

$PLAN_CMD -out=tfplan

echo ""
echo -e "${GREEN}✅ Plan généré : terraform/tfplan${NC}"
echo ""

# Si plan-only, on s'arrête ici
if [ "$PLAN_ONLY" = true ]; then
    echo -e "${BLUE}========================================${NC}"
    echo -e "${GREEN}✅ Plan généré (mode plan-only)${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo "Pour appliquer ce plan :"
    echo "  cd $TERRAFORM_DIR"
    echo "  tofu apply tfplan"
    exit 0
fi

# Application
if [ "$AUTO_APPLY" = true ]; then
    echo -e "${BLUE}🚀 Application du plan (auto-apply)...${NC}"
    tofu apply -auto-approve tfplan
else
    echo -e "${BLUE}🚀 Application du plan...${NC}"
    tofu apply tfplan
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✅ Infrastructure déployée${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Afficher les ressources créées
echo -e "${BLUE}📊 Ressources Terraform :${NC}"
tofu state list | head -20
RESOURCE_COUNT=$(tofu state list | wc -l | tr -d ' ')
echo -e "   ${CYAN}Total : ${RESOURCE_COUNT} ressources${NC}"
echo ""

echo -e "${BLUE}Prochaines étapes :${NC}"
echo -e "  1. Vérifier l'inventaire Ansible : ${CYAN}cat ../ansible/inventory/proxmox/inventory.ini${NC}"
echo -e "  2. Configurer les VMs avec Ansible : ${CYAN}./deploy-ansible.sh${NC}"
echo ""
