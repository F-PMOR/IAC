#!/bin/bash

###############################################################################
# Script: import-terraform-vms.sh
# Description: Importe automatiquement les VMs existantes dans l'état Terraform
#              en utilisant les informations des fichiers CSV (par provider)
# Usage: ./scripts/import-terraform-vms.sh [-a|--all] [-v|--vm <vm_name>] [-p|--provider <proxmox|vmware>]
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
PROVIDER=""

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
        -p|--provider)
            PROVIDER="$2"
            if [[ "$PROVIDER" != "proxmox" && "$PROVIDER" != "vmware" ]]; then
                echo -e "${RED}❌ Provider invalide: $PROVIDER${NC}"
                echo "   Valeurs acceptées: proxmox, vmware"
                exit 1
            fi
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  -a, --all              Importer toutes les VMs des fichiers CSV"
            echo "  -v, --vm <name>        Importer une VM spécifique"
            echo "  -p, --provider <type>  Filtrer par provider (proxmox ou vmware)"
            echo "  -h, --help             Afficher cette aide"
            echo ""
            echo "Exemples:"
            echo "  $0 --all                           # Importer toutes les VMs"
            echo "  $0 --all --provider proxmox        # Importer toutes les VMs Proxmox"
            echo "  $0 --vm mysql-prod01               # Importer une VM spécifique"
            echo "  $0 --vm mysql-prod01 --provider proxmox  # Importer une VM Proxmox"
            exit 0
            ;;
        *)
            echo -e "${RED}Option inconnue: $1${NC}"
            exit 1
            ;;
    esac
done

# Vérifier qu'au moins une option est fournie
if [ "$IMPORT_ALL" = false ] && [ -z "$VM_NAME" ]; then
    echo -e "${RED}❌ Erreur: Vous devez spécifier --all ou --vm <name>${NC}"
    echo "   Utilisez --help pour voir les options disponibles"
    exit 1
fi

echo "========================================"
echo "  IMPORT DES VMS DANS TERRAFORM"
echo "========================================"
echo ""

# Fonction pour importer une VM Proxmox
import_proxmox_vm() {
    local name=$1
    local vmid=$2
    local node=$3
    
    # Transformer le nom (remplacer - par _ comme dans vms-proxmox.tf)
    local terraform_name=$(echo "$name" | tr '-' '_')
    
    echo -e "${BLUE}📦 Import de la VM Proxmox: $name (VMID: $vmid, Node: $node)${NC}"
    
    # Vérifier si la VM existe dans l'état
    if (cd "$PROJECT_ROOT/terraform" && tofu state list) | grep -q "proxmox_virtual_environment_vm.proxmox_vms\[\"$terraform_name\"\]"; then
        echo -e "   ${YELLOW}⚠️  VM déjà dans l'état Terraform${NC}"
        return
    fi
    
    # Importer la VM avec le format node/vmid (rester dans le bon répertoire)
    if (cd "$PROJECT_ROOT/terraform" && tofu import "proxmox_virtual_environment_vm.proxmox_vms[\"$terraform_name\"]" "$node/$vmid") 2>&1; then
        echo -e "   ${GREEN}✅ VM importée avec succès${NC}"
    else
        echo -e "   ${RED}❌ Erreur lors de l'import${NC}"
    fi
}

# Fonction pour importer une VM VMware
import_vmware_vm() {
    local name=$1
    local vmid=$2
    local datacenter=$3
    
    echo -e "${BLUE}📦 Import de la VM VMware: $name (ID: $vmid, Datacenter: $datacenter)${NC}"
    
    # Vérifier si la VM existe dans l'état
    if (cd "$PROJECT_ROOT/terraform" && tofu state list) | grep -q "vsphere_virtual_machine.vmware_vms\[\"$name\"\]"; then
        echo -e "   ${YELLOW}⚠️  VM déjà dans l'état Terraform${NC}"
        return
    fi
    
    # Pour VMware, l'import nécessite le chemin complet de la VM
    # Format: /<datacenter>/vm/<vm_path>/<vm_name>
    local vm_path="/$datacenter/vm/$name"
    
    # Importer la VM (rester dans le bon répertoire)
    if (cd "$PROJECT_ROOT/terraform" && tofu import "vsphere_virtual_machine.vmware_vms[\"$name\"]" "$vm_path") 2>&1; then
        echo -e "   ${GREEN}✅ VM importée avec succès${NC}"
    else
        echo -e "   ${RED}❌ Erreur lors de l'import${NC}"
        echo -e "   ${YELLOW}💡 Vérifiez le chemin de la VM dans vCenter${NC}"
    fi
}

# Initialiser Terraform si nécessaire
cd "$PROJECT_ROOT/terraform"
if [ ! -d ".terraform" ]; then
    echo -e "${BLUE}🔧 Initialisation de Terraform...${NC}"
    tofu init
    echo ""
fi

# Import des VMs Proxmox
if [ -z "$PROVIDER" ] || [ "$PROVIDER" = "proxmox" ]; then
    if [ -f "$PROJECT_ROOT/config/vms-proxmox.csv" ]; then
        echo -e "${BLUE}📋 Lecture du fichier vms-proxmox.csv...${NC}"
        echo ""
        
        # Compter les VMs (exclure l'en-tête)
        VM_COUNT=$(tail -n +2 "$PROJECT_ROOT/config/vms-proxmox.csv" | grep -v '^[[:space:]]*$' | wc -l | tr -d ' ')
        
        if [ "$VM_COUNT" -gt 0 ]; then
            if [ "$IMPORT_ALL" = true ]; then
                echo -e "${GREEN}Mode: Import de toutes les VMs Proxmox ($VM_COUNT VM(s))${NC}"
                echo ""
                
                # Parser le CSV et importer chaque VM
                tail -n +2 "$PROJECT_ROOT/config/vms-proxmox.csv" | while IFS=',' read -r name vmid environment node rest; do
                    # Nettoyer les espaces et guillemets
                    name=$(echo "$name" | tr -d '"' | xargs)
                    vmid=$(echo "$vmid" | tr -d '"' | xargs)
                    node=$(echo "$node" | tr -d '"' | xargs)
                    
                    # Ignorer les lignes vides
                    if [ -z "$name" ] || [ -z "$vmid" ]; then
                        continue
                    fi
                    
                    import_proxmox_vm "$name" "$vmid" "$node"
                    echo ""
                done
            elif [ -n "$VM_NAME" ]; then
                # Chercher la VM spécifique
                VM_FOUND=false
                tail -n +2 "$PROJECT_ROOT/config/vms-proxmox.csv" | while IFS=',' read -r name vmid environment node rest; do
                    name=$(echo "$name" | tr -d '"' | xargs)
                    vmid=$(echo "$vmid" | tr -d '"' | xargs)
                    node=$(echo "$node" | tr -d '"' | xargs)
                    
                    if [ "$name" = "$VM_NAME" ]; then
                        VM_FOUND=true
                        import_proxmox_vm "$name" "$vmid" "$node"
                        echo ""
                        exit 0
                    fi
                done
                
                if [ "$VM_FOUND" = false ]; then
                    echo -e "${RED}❌ VM '$VM_NAME' non trouvée dans vms-proxmox.csv${NC}"
                fi
            fi
        else
            echo -e "${YELLOW}⚠️  Aucune VM trouvée dans vms-proxmox.csv${NC}"
            echo ""
        fi
    else
        echo -e "${YELLOW}⚠️  Fichier vms-proxmox.csv non trouvé${NC}"
        echo ""
    fi
fi

# Import des VMs VMware
if [ -z "$PROVIDER" ] || [ "$PROVIDER" = "vmware" ]; then
    if [ -f "$PROJECT_ROOT/config/vms-vmware.csv" ]; then
        echo -e "${BLUE}📋 Lecture du fichier vms-vmware.csv...${NC}"
        echo ""
        
        # Compter les VMs (exclure l'en-tête)
        VM_COUNT=$(tail -n +2 "$PROJECT_ROOT/config/vms-vmware.csv" | grep -v '^[[:space:]]*$' | wc -l | tr -d ' ')
        
        if [ "$VM_COUNT" -gt 0 ]; then
            if [ "$IMPORT_ALL" = true ]; then
                echo -e "${GREEN}Mode: Import de toutes les VMs VMware ($VM_COUNT VM(s))${NC}"
                echo ""
                
                # Parser le CSV et importer chaque VM
                tail -n +2 "$PROJECT_ROOT/config/vms-vmware.csv" | while IFS=',' read -r name vmid environment datacenter cluster rest; do
                    # Nettoyer les espaces et guillemets
                    name=$(echo "$name" | tr -d '"' | xargs)
                    vmid=$(echo "$vmid" | tr -d '"' | xargs)
                    datacenter=$(echo "$datacenter" | tr -d '"' | xargs)
                    
                    # Ignorer les lignes vides
                    if [ -z "$name" ] || [ -z "$vmid" ]; then
                        continue
                    fi
                    
                    import_vmware_vm "$name" "$vmid" "$datacenter"
                    echo ""
                done
            elif [ -n "$VM_NAME" ]; then
                # Chercher la VM spécifique
                VM_FOUND=false
                tail -n +2 "$PROJECT_ROOT/config/vms-vmware.csv" | while IFS=',' read -r name vmid environment datacenter cluster rest; do
                    name=$(echo "$name" | tr -d '"' | xargs)
                    vmid=$(echo "$vmid" | tr -d '"' | xargs)
                    datacenter=$(echo "$datacenter" | tr -d '"' | xargs)
                    
                    if [ "$name" = "$VM_NAME" ]; then
                        VM_FOUND=true
                        import_vmware_vm "$name" "$vmid" "$datacenter"
                        echo ""
                        exit 0
                    fi
                done
                
                if [ "$VM_FOUND" = false ]; then
                    echo -e "${RED}❌ VM '$VM_NAME' non trouvée dans vms-vmware.csv${NC}"
                fi
            fi
        else
            echo -e "${YELLOW}⚠️  Aucune VM trouvée dans vms-vmware.csv${NC}"
            echo ""
        fi
    else
        echo -e "${YELLOW}⚠️  Fichier vms-vmware.csv non trouvé${NC}"
        echo ""
    fi
fi

echo -e "${GREEN}✅ Import terminé !${NC}"
echo ""
echo -e "${BLUE}💡 Vérifiez l'état avec:${NC}"
echo "   cd $PROJECT_ROOT/terraform"
echo "   tofu state list"
