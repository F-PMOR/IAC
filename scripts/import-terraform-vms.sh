#!/bin/bash

###############################################################################
# Script: import-terraform-vms.sh
# Description: Importe automatiquement les VMs existantes dans l'état Terraform
#              en utilisant les informations du fichier CSV
# Usage: ./scripts/import-terraform-vms.sh [-a|--all] [-v|--vm <vm_name>]
###############################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

IMPORT_ALL=false
VM_NAME=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -a|--all)
            IMPORT_ALL=true
            shift
            ;;
        -v|--vm)
            VM_NAME="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [-a|--all] [-v|--vm <vm_name>]"
            echo ""
            echo "Importe les VMs existantes dans l'état Terraform."
            echo ""
            echo "Options:"
            echo "  -a, --all           Importer toutes les VMs du CSV"
            echo "  -v, --vm <name>     Importer une VM spécifique"
            echo "  -h, --help          Afficher cette aide"
            echo ""
            echo "Exemples:"
            echo "  $0 --all                      # Importer toutes les VMs"
            echo "  $0 --vm dolibarr-prod01       # Importer une VM spécifique"
            exit 0
            ;;
        *)
            echo -e "${RED}Option inconnue: $1${NC}"
            exit 1
            ;;
    esac
done

if [ "$IMPORT_ALL" = false ] && [ -z "$VM_NAME" ]; then
    echo -e "${RED}❌ Erreur: Vous devez spécifier --all ou --vm <name>${NC}"
    echo "Usage: $0 [-a|--all] [-v|--vm <vm_name>]"
    exit 1
fi

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Import de VMs dans Terraform${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Vérifier que le CSV existe
if [ ! -f "$PROJECT_ROOT/config/vms.csv" ]; then
    echo -e "${RED}❌ Fichier CSV non trouvé: config/vms.csv${NC}"
    exit 1
fi

# Fonction pour importer une VM
import_vm() {
    local vm_name=$1
    local vmid=$2
    local node=$3
    local provider=$4
    
    if [ "$provider" != "proxmox" ]; then
        echo -e "${YELLOW}⏭️  VM $vm_name ignorée (provider: $provider)${NC}"
        return 0
    fi
    
    echo -e "${BLUE}📥 Import de $vm_name (ID: $vmid sur $node)...${NC}"
    
    # Vérifier si la VM existe déjà dans l'état
    local state_check=$(cd /root/terraform && tofu state list 2>/dev/null | grep -c "proxmox_virtual_environment_vm.vms_csv\[\"$vm_name\"\]" || true)
    
    if [ "$state_check" -gt 0 ]; then
        echo -e "${YELLOW}⚠️  VM $vm_name déjà présente dans l'état Terraform${NC}"
        return 0
    fi
    
    # Importer la VM
    local import_result=$(cd /root/terraform && \
        tofu import "proxmox_virtual_environment_vm.vms_csv[\"$vm_name\"]" $node/$vmid 2>&1
    )
    
    if echo "$import_result" | grep -q "Import successful"; then
        echo -e "${GREEN}✅ VM $vm_name importée avec succès${NC}"
        return 0
    else
        echo -e "${RED}❌ Erreur lors de l'import de $vm_name${NC}"
        echo "$import_result"
        return 1
    fi
}

# Lire le CSV et importer les VMs
echo "📋 Lecture du fichier CSV..."
echo ""

# Convertir CSV en YAML pour avoir les données structurées
cd /root/config && python3 csv-to-config.py > /dev/null

# Lire le YAML et extraire les informations
if [ "$IMPORT_ALL" = true ]; then
    echo -e "${GREEN}Mode: Import de toutes les VMs${NC}"
    echo ""
    
    # Parser le CSV et importer chaque VM Proxmox
    tail -n +2 "$PROJECT_ROOT/config/vms.csv" | while IFS=',' read -r name vmid environment provider node rest; do
        # Nettoyer les espaces et guillemets
        name=$(echo "$name" | tr -d '"' | xargs)
        vmid=$(echo "$vmid" | tr -d '"' | xargs)
        node=$(echo "$node" | tr -d '"' | xargs)
        provider=$(echo "$provider" | tr -d '"' | xargs)
        
        # Ignorer les lignes vides
        if [ -z "$name" ] || [ -z "$vmid" ]; then
            continue
        fi
        
        import_vm "$name" "$vmid" "$node" "$provider"
        echo ""
    done
else
    echo -e "${GREEN}Mode: Import de la VM $VM_NAME${NC}"
    echo ""
    
    # Rechercher la VM spécifique dans le CSV
    vm_line=$(tail -n +2 "$PROJECT_ROOT/config/vms.csv" | grep "^$VM_NAME,")
    
    if [ -z "$vm_line" ]; then
        echo -e "${RED}❌ VM $VM_NAME non trouvée dans le CSV${NC}"
        exit 1
    fi
    
    # Extraire les informations
    vmid=$(echo "$vm_line" | cut -d',' -f2 | tr -d '"' | xargs)
    provider=$(echo "$vm_line" | cut -d',' -f4 | tr -d '"' | xargs)
    node=$(echo "$vm_line" | cut -d',' -f5 | tr -d '"' | xargs)
    
    import_vm "$VM_NAME" "$vmid" "$node" "$provider"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ Import terminé${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Pour vérifier l'état Terraform :"
echo "  tofu state list"
echo ""
echo "Pour vérifier qu'il n'y a pas de changements prévus :"
echo "  ./scripts/deploy-terraform.sh -p"
echo ""
