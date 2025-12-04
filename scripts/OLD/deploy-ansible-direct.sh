#!/bin/bash

###############################################################################
# Script: deploy-ansible-direct.sh
# Description: Lance les playbooks Ansible directement depuis le CSV
#              sans passer par un wrapper Ansible
# Usage: ./scripts/deploy-ansible-direct.sh [options]
###############################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Options par défaut
SKIP_EXISTING=false
ALL_VMS=false
PARALLEL=3
VM_FILTER=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-existing)
            SKIP_EXISTING=true
            shift
            ;;
        -a|--all)
            ALL_VMS=true
            shift
            ;;
        -p|--parallel)
            PARALLEL="$2"
            shift 2
            ;;
        -v|--vm)
            VM_FILTER="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --skip-existing    Ne configurer que les VMs nouvellement créées"
            echo "  -a, --all          Configurer toutes les VMs"
            echo "  -p, --parallel N   Nombre de VMs à configurer en parallèle (défaut: 3)"
            echo "  -v, --vm <name>    Configurer une VM spécifique"
            echo "  -h, --help         Afficher cette aide"
            exit 0
            ;;
        *)
            echo -e "${RED}Option inconnue: $1${NC}"
            exit 1
            ;;
    esac
done

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}      DÉPLOIEMENT ANSIBLE DIRECT${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Convertir le CSV en YAML si nécessaire
if [ ! -f "$PROJECT_ROOT/config/vms-config.yml" ]; then
    echo -e "${YELLOW}⚠️  Fichier vms-config.yml non trouvé, conversion du CSV...${NC}"
    python3 /root/config/csv-to-config.py
fi

# Fonction pour lancer les playbooks d'une VM
execute_vm_playbooks() {
    local vm_name=$1
    local playbooks=$2
    local inventory="/root/ansible/inventory/proxmox/inventory.ini"
    local playbooks_dir="/root/ansible/playbooks"
    
    echo -e "${CYAN}📦 Configuration de ${vm_name}...${NC}"
    
    # Parser les playbooks (format: "playbook1.yml,playbook2.yml")
    IFS=',' read -ra PLAYBOOK_ARRAY <<< "$playbooks"
    
    local failed=false
    for playbook in "${PLAYBOOK_ARRAY[@]}"; do
        playbook=$(echo "$playbook" | xargs) # Trim whitespace
        
        echo -e "${BLUE}  ▶ ${vm_name}: ${playbook}${NC}"
        
        # Extraire les variables si elles existent (format: playbook.yml|var1=val1|var2=val2)
        local playbook_name="${playbook%%|*}"
        local extra_vars=""
        
        if [[ "$playbook" == *"|"* ]]; then
            local vars_part="${playbook#*|}"
            IFS='|' read -ra VAR_ARRAY <<< "$vars_part"
            for var in "${VAR_ARRAY[@]}"; do
                extra_vars="$extra_vars -e $var"
            done
        fi
        
        # Lancer le playbook
        if ANSIBLE_FORCE_COLOR=true ANSIBLE_NOCOLOR=false ansible-playbook -i $inventory $playbooks_dir/$playbook_name --limit $vm_name $extra_vars < /dev/null; then
            echo -e "${GREEN}  ✅ ${vm_name}: ${playbook_name} - OK${NC}\n"
        else
            echo -e "${RED}  ❌ ${vm_name}: ${playbook_name} - FAILED${NC}\n"
            failed=true
            break
        fi
    done
    
    if [ "$failed" = true ]; then
        return 1
    fi
    
    echo -e "${GREEN}✅ ${vm_name} - Configuration terminée${NC}"
    echo ""
    return 0
}

# Export la fonction pour GNU parallel ou xargs
export -f execute_vm_playbooks
export RED GREEN YELLOW BLUE CYAN NC

# Récupérer la liste des VMs et leurs playbooks depuis le YAML
echo -e "${YELLOW}📋 Lecture de la configuration...${NC}"
echo ""

# Utiliser Python pour parser le YAML et générer les commandes
vm_playbooks=$(python3 -c "
import yaml
import sys

try:
    with open('/root/config/vms-config.yml', 'r') as f:
        config = yaml.safe_load(f)
    
    vms = config.get('vms', [])
    
    for vm in vms:
        name = vm.get('name', '')
        playbooks = vm.get('playbooks', [])
        
        if not playbooks:
            continue
        
        # Créer une liste de playbooks avec leurs variables
        playbook_list = []
        for pb in playbooks:
            pb_name = pb.get('name', '')
            pb_vars = pb.get('vars', {})
            
            if pb_vars:
                vars_str = '|'.join([f'{k}={v}' for k, v in pb_vars.items()])
                playbook_list.append(f'{pb_name}|{vars_str}')
            else:
                playbook_list.append(pb_name)
        
        # Format: vm_name:playbook1,playbook2
        print(f\"{name}:{','.join(playbook_list)}\")

except Exception as e:
    print(f'Error: {e}', file=sys.stderr)
    sys.exit(1)
")

if [ -z "$vm_playbooks" ]; then
    echo -e "${RED}❌ Aucune VM trouvée dans la configuration${NC}"
    exit 1
fi

# Filtrer les VMs si nécessaire
if [ -n "$VM_FILTER" ]; then
    vm_playbooks=$(echo "$vm_playbooks" | grep "^$VM_FILTER:")
    if [ -z "$vm_playbooks" ]; then
        echo -e "${RED}❌ VM $VM_FILTER non trouvée${NC}"
        exit 1
    fi
    echo -e "${GREEN}Mode: Configuration de la VM $VM_FILTER${NC}"
else
    echo -e "${GREEN}Mode: Configuration de toutes les VMs${NC}"
fi

echo -e "${YELLOW}Parallélisme: $PARALLEL VM(s) à la fois${NC}"
echo ""

# Compter le nombre de VMs
vm_count=$(echo "$vm_playbooks" | wc -l | xargs)
echo -e "${CYAN}📊 ${vm_count} VM(s) à configurer${NC}"
echo ""

# Lancer les configurations en parallèle
pids=()
while IFS=: read -r vm_name playbooks; do
    execute_vm_playbooks "$vm_name" "$playbooks" &
    pids+=($!)
    
    # Limiter le nombre de jobs parallèles
    while [ "$(jobs -r | wc -l)" -ge "$PARALLEL" ]; do
        sleep 1
    done
done <<< "$vm_playbooks"

# Attendre que tous les jobs se terminent explicitement
for pid in "${pids[@]}"; do
    wait "$pid" 2>/dev/null || true
done

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ Configuration Ansible terminée${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
