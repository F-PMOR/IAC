#!/bin/bash

###############################################################################
# Script: destroy-vms.sh
# Description: Détruit une ou plusieurs VMs gérées par Terraform
# Usage: ./scripts/destroy-vms.sh [options]
###############################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

VM_NAME=""
PROVIDER=""
PLAN_ONLY=false
AUTO_CONFIRM=false
LIST_ONLY=false
DESTROY_ALL=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--vm)
            VM_NAME="$2"
            shift 2
            ;;
        -p|--provider)
            PROVIDER="$2"
            if [[ "$PROVIDER" != "proxmox" && "$PROVIDER" != "vmware" ]]; then
                echo -e "${RED}❌ Provider invalide: $PROVIDER${NC}"
                echo "   Valeurs acceptées: proxmox, vmware"
                exit 1
            fi
            shift 2
            ;;
        --plan)
            PLAN_ONLY=true
            shift
            ;;
        -y|--yes)
            AUTO_CONFIRM=true
            shift
            ;;
        -l|--list)
            LIST_ONLY=true
            shift
            ;;
        -a|--all)
            DESTROY_ALL=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  -v, --vm <name>        Nom de la VM à détruire"
            echo "  -p, --provider <type>  Provider (proxmox ou vmware)"
            echo "  -a, --all              Détruire TOUTES les VMs d'un provider (requiert --provider)"
            echo "  --plan                 Afficher le plan de destruction sans détruire"
            echo "  -y, --yes              Confirmer automatiquement la destruction"
            echo "  -l, --list             Lister les VMs gérées par Terraform"
            echo "  -h, --help             Afficher cette aide"
            echo ""
            echo "Exemples:"
            echo "  $0 --list                              # Lister toutes les VMs"
            echo "  $0 --vm mysql-prod01 --plan           # Voir le plan de destruction"
            echo "  $0 --vm mysql-prod01 --provider proxmox  # Détruire une VM"
            echo "  $0 --vm mysql-prod01 -y                # Détruire sans confirmation"
            echo "  $0 --all --provider proxmox --plan    # Plan pour détruire toutes les VMs Proxmox"
            echo "  $0 --all --provider vmware -y          # Détruire toutes les VMs VMware (sans confirmation)"
            exit 0
            ;;
        *)
            echo -e "${RED}Option inconnue: $1${NC}"
            exit 1
            ;;
    esac
done

echo "========================================"
echo "  DESTRUCTION DE VMS TERRAFORM"
echo "========================================"
echo ""

cd "$PROJECT_ROOT/terraform"

# Lister les VMs
if [ "$LIST_ONLY" = true ]; then
    echo -e "${BLUE}📋 VMs gérées par Terraform :${NC}"
    echo ""
    
    if ! tofu state list | grep -q "proxmox_virtual_environment_vm\|vsphere_virtual_machine"; then
        echo -e "${YELLOW}⚠️  Aucune VM trouvée dans l'état Terraform${NC}"
        exit 0
    fi
    
    echo -e "${MAGENTA}=== VMs Proxmox ===${NC}"
    tofu state list | grep "proxmox_virtual_environment_vm" | while read -r resource; do
        # Extraire le nom de la VM
        vm_name=$(echo "$resource" | sed 's/.*\["\(.*\)"\].*/\1/' | tr '_' '-')
        echo -e "  ${GREEN}•${NC} $vm_name"
    done
    
    echo ""
    echo -e "${MAGENTA}=== VMs VMware ===${NC}"
    if tofu state list | grep -q "vsphere_virtual_machine"; then
        tofu state list | grep "vsphere_virtual_machine" | while read -r resource; do
            vm_name=$(echo "$resource" | sed 's/.*\["\(.*\)"\].*/\1/' | tr '_' '-')
            echo -e "  ${GREEN}•${NC} $vm_name"
        done
    else
        echo -e "  ${YELLOW}(aucune)${NC}"
    fi
    
    exit 0
fi

# Mode destruction de toutes les VMs d'un provider
if [ "$DESTROY_ALL" = true ]; then
    # Vérifier qu'un provider est spécifié
    if [ -z "$PROVIDER" ]; then
        echo -e "${RED}❌ Erreur: --all requiert l'option --provider${NC}"
        echo "   Exemple: $0 --all --provider proxmox"
        exit 1
    fi
    
    # Déterminer le type de ressource
    if [ "$PROVIDER" = "proxmox" ]; then
        RESOURCE_TYPE="proxmox_virtual_environment_vm.proxmox_vms"
    else
        RESOURCE_TYPE="vsphere_virtual_machine.vmware_vms"
    fi
    
    # Compter les VMs
    VM_COUNT=$(tofu state list | grep -c "$RESOURCE_TYPE" || true)
    
    if [ "$VM_COUNT" -eq 0 ]; then
        echo -e "${YELLOW}⚠️  Aucune VM $PROVIDER trouvée dans l'état Terraform${NC}"
        exit 0
    fi
    
    echo -e "${BLUE}🎯 Provider ciblé : ${MAGENTA}$PROVIDER${NC}"
    echo -e "${BLUE}📊 VMs à détruire : ${MAGENTA}$VM_COUNT${NC}"
    echo ""
    
    # Lister les VMs qui seront détruites
    echo -e "${YELLOW}VMs qui seront détruites :${NC}"
    tofu state list | grep "$RESOURCE_TYPE" | while read -r resource; do
        vm_name=$(echo "$resource" | sed 's/.*\["\(.*\)"\].*/\1/' | tr '_' '-')
        echo -e "  ${RED}•${NC} $vm_name"
    done
    echo ""
    
    # Plan de destruction
    if [ "$PLAN_ONLY" = true ]; then
        echo -e "${YELLOW}📋 Génération du plan de destruction...${NC}"
        echo ""
        tofu plan -destroy -target="$RESOURCE_TYPE"
        echo ""
        echo -e "${BLUE}💡 Pour détruire réellement, exécutez :${NC}"
        echo "   $0 --all --provider $PROVIDER"
        exit 0
    fi
    
    # Confirmation
    if [ "$AUTO_CONFIRM" = false ]; then
        echo -e "${RED}⚠️  ATTENTION : Cette action va DÉTRUIRE TOUTES les VMs $PROVIDER !${NC}"
        echo ""
        echo -e "${YELLOW}Cette action est IRRÉVERSIBLE !${NC}"
        echo -e "${YELLOW}$VM_COUNT VM(s) seront détruites !${NC}"
        echo ""
        read -p "Êtes-vous ABSOLUMENT sûr de vouloir continuer ? (tapez 'DESTROY ALL' pour confirmer) : " confirm
        
        if [ "$confirm" != "DESTROY ALL" ]; then
            echo -e "${BLUE}❌ Destruction annulée${NC}"
            exit 0
        fi
    fi
    
    # Destruction
    echo ""
    echo -e "${RED}🔥 Destruction de toutes les VMs $PROVIDER en cours...${NC}"
    echo ""
    
    if tofu destroy -target="$RESOURCE_TYPE" -auto-approve; then
        echo ""
        echo -e "${GREEN}✅ Toutes les VMs $PROVIDER ont été détruites !${NC}"
        echo ""
        echo -e "${BLUE}💡 N'oubliez pas de :${NC}"
        echo "   1. Vider le fichier CSV correspondant"
        if [ "$PROVIDER" = "proxmox" ]; then
            echo "      - config/vms-proxmox.csv"
        else
            echo "      - config/vms-vmware.csv"
        fi
        echo "   2. Regénérer les inventaires Ansible avec : tofu apply"
    else
        echo ""
        echo -e "${RED}❌ Erreur lors de la destruction des VMs${NC}"
        exit 1
    fi
    
    exit 0
fi

# Vérifier qu'une VM est spécifiée
if [ -z "$VM_NAME" ]; then
    echo -e "${RED}❌ Erreur: Vous devez spécifier une VM avec --vm${NC}"
    echo "   Utilisez --list pour voir les VMs disponibles"
    echo "   Utilisez --help pour voir toutes les options"
    exit 1
fi

# Transformer le nom (- vers _ pour Terraform)
TERRAFORM_NAME=$(echo "$VM_NAME" | tr '-' '_')

# Déterminer le type de ressource
if [ -z "$PROVIDER" ]; then
    # Auto-détection du provider
    if tofu state list | grep -q "proxmox_virtual_environment_vm.proxmox_vms\[\"$TERRAFORM_NAME\"\]"; then
        PROVIDER="proxmox"
        RESOURCE="proxmox_virtual_environment_vm.proxmox_vms[\"$TERRAFORM_NAME\"]"
    elif tofu state list | grep -q "vsphere_virtual_machine.vmware_vms\[\"$TERRAFORM_NAME\"\]"; then
        PROVIDER="vmware"
        RESOURCE="vsphere_virtual_machine.vmware_vms[\"$TERRAFORM_NAME\"]"
    else
        echo -e "${RED}❌ VM '$VM_NAME' non trouvée dans l'état Terraform${NC}"
        echo ""
        echo "VMs disponibles :"
        tofu state list | grep -E "proxmox_virtual_environment_vm|vsphere_virtual_machine" | sed 's/.*\["\(.*\)"\].*/  - \1/' | tr '_' '-'
        exit 1
    fi
else
    # Provider spécifié explicitement
    if [ "$PROVIDER" = "proxmox" ]; then
        RESOURCE="proxmox_virtual_environment_vm.proxmox_vms[\"$TERRAFORM_NAME\"]"
    else
        RESOURCE="vsphere_virtual_machine.vmware_vms[\"$TERRAFORM_NAME\"]"
    fi
    
    # Vérifier que la ressource existe
    if ! tofu state list | grep -q "$RESOURCE"; then
        echo -e "${RED}❌ VM '$VM_NAME' non trouvée dans l'état Terraform (provider: $PROVIDER)${NC}"
        exit 1
    fi
fi

echo -e "${BLUE}🎯 VM ciblée : ${MAGENTA}$VM_NAME${NC}"
echo -e "${BLUE}📦 Provider  : ${MAGENTA}$PROVIDER${NC}"
echo -e "${BLUE}🔧 Ressource : ${MAGENTA}$RESOURCE${NC}"
echo ""

# Plan de destruction
if [ "$PLAN_ONLY" = true ]; then
    echo -e "${YELLOW}📋 Génération du plan de destruction...${NC}"
    echo ""
    tofu plan -destroy -target="$RESOURCE"
    echo ""
    echo -e "${BLUE}💡 Pour détruire réellement, exécutez :${NC}"
    echo "   $0 --vm $VM_NAME --provider $PROVIDER"
    exit 0
fi

# Confirmation
if [ "$AUTO_CONFIRM" = false ]; then
    echo -e "${RED}⚠️  ATTENTION : Cette action va DÉTRUIRE la VM !${NC}"
    echo ""
    echo -e "VM à détruire : ${MAGENTA}$VM_NAME${NC} ($PROVIDER)"
    echo ""
    echo -e "${YELLOW}Cette action est IRRÉVERSIBLE !${NC}"
    echo ""
    read -p "Êtes-vous sûr de vouloir continuer ? (tapez 'oui' pour confirmer) : " confirm
    
    if [ "$confirm" != "oui" ]; then
        echo -e "${BLUE}❌ Destruction annulée${NC}"
        exit 0
    fi
fi

# Destruction
echo ""
echo -e "${RED}🔥 Destruction de la VM en cours...${NC}"
echo ""

if tofu destroy -target="$RESOURCE" -auto-approve; then
    echo ""
    echo -e "${GREEN}✅ VM '$VM_NAME' détruite avec succès !${NC}"
    echo ""
    echo -e "${BLUE}💡 N'oubliez pas de :${NC}"
    echo "   1. Supprimer la ligne correspondante dans le CSV"
    echo "      - config/vms-proxmox.csv (si Proxmox)"
    echo "      - config/vms-vmware.csv (si VMware)"
    echo "   2. Regénérer les inventaires Ansible avec : tofu apply"
else
    echo ""
    echo -e "${RED}❌ Erreur lors de la destruction de la VM${NC}"
    exit 1
fi
