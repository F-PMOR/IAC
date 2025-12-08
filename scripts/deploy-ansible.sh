#!/bin/bash

###############################################################################
# Script: deploy-ansible.sh
# Description: Lance l'orchestrateur Ansible de manière native
# Usage: ./scripts/deploy-ansible.sh [options]
#
# Inventaires disponibles (variable INVENTORY_FILE):
#  - inventory/proxmox/inventory.ini  (par défaut) : VMs Proxmox uniquement
#  - inventory/vmware/inventory.ini   : VMs VMware uniquement
#  - inventory/all/inventory.ini      : Toutes les VMs (Proxmox + VMware)
#
# Exemples d'utilisation :
#  ./deploy-ansible.sh -l prod -t post-install,mysql
#  ./deploy-ansible.sh -l dev -t dolibarr
#  INVENTORY_FILE=./ansible/inventory/all/inventory.ini ./deploy-ansible.sh
#  INVENTORY_FILE=./ansible/inventory/vmware/inventory.ini ./deploy-ansible.sh -l vmware_prod
###############################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Chemins
ANSIBLE_DIR="${PROJECT_ROOT}/ansible"
INVENTORY_FILE="${INVENTORY_FILE:-${ANSIBLE_DIR}/inventory/proxmox/inventory.ini}"
ORCHESTRATE_PLAYBOOK="${ORCHESTRATE_PLAYBOOK:-${ANSIBLE_DIR}/playbooks/orchestrate.yml}"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Options par défaut
LIMIT=""
TAGS=""
SKIP_TAGS=""
EXTRA_VARS=""
CHECK_MODE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -l|--limit)
            LIMIT="$2"
            shift 2
            ;;
        -t|--tags)
            TAGS="$2"
            shift 2
            ;;
        -s|--skip-tags)
            SKIP_TAGS="$2"
            shift 2
            ;;
        -e|--extra-vars)
            EXTRA_VARS="$2"
            shift 2
            ;;
        -c|--check)
            CHECK_MODE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Orchestrateur Ansible pour déployer les configurations sur les VMs"
            echo ""
            echo "Options:"
            echo "  -l, --limit <pattern>      Limiter à un groupe ou VM spécifique"
            echo "  -t, --tags <tags>          Exécuter uniquement ces tags (séparés par ,)"
            echo "  -s, --skip-tags <tags>     Sauter ces tags (séparés par ,)"
            echo "  -e, --extra-vars <vars>    Variables supplémentaires (format key=value)"
            echo "  -c, --check                Mode dry-run (ne fait pas de changements)"
            echo "  -h, --help                 Afficher cette aide"
            echo ""
            echo "Exemples:"
            echo "  $0                                    # Toutes les VMs, tous les playbooks"
            echo "  $0 --limit prod                       # Seulement les VMs du groupe 'prod'"
            echo "  $0 --limit mysql-prod01               # Une seule VM"
            echo "  $0 --tags mysql                       # Seulement les playbooks MySQL"
            echo "  $0 --tags dolibarr --limit dev        # Dolibarr sur les VMs dev"
            echo "  $0 --skip-tags post-install           # Tout sauf post-installation"
            echo "  $0 --check                            # Voir ce qui serait changé"
            echo ""
            echo "Inventaires (via variable INVENTORY_FILE):"
            echo "  - inventory/proxmox/inventory.ini  (défaut) : VMs Proxmox uniquement"
            echo "  - inventory/vmware/inventory.ini             : VMs VMware uniquement"
            echo "  - inventory/all/inventory.ini                : Toutes les VMs"
            echo ""
            echo "  Exemple : INVENTORY_FILE=./ansible/inventory/all/inventory.ini $0"
            echo ""
            echo "Tags disponibles:"
            echo "  - qemu-agent, agent, proxmox : Installation QEMU Guest Agent (Proxmox)"
            echo "  - vmware-tools, agent, vmware : Installation VMware Tools (vSphere)"
            echo "  - post-install : Post-installation système"
            echo "  - mysql, databases : Configuration MySQL/MariaDB"
            echo "  - dolibarr, web : Déploiement Dolibarr"
            echo "  - restore-dolibarr : Restauration Dolibarr"
            echo ""
            echo "Groupes disponibles:"
            echo "  - all : Toutes les VMs"
            echo "  - prod : VMs de production"
            echo "  - preprod : VMs de pré-production"
            echo "  - dev : VMs de développement"
            echo "  - databases : Serveurs de bases de données"
            echo "  - webservers : Serveurs web"
            echo "  - dolibarr : Serveurs Dolibarr"
            echo ""
            echo "Groupes disponibles (dépendent de l'inventaire utilisé):"
            echo "  Inventaire Proxmox/VMware :"
            echo "    - all, prod, preprod, dev, databases, webservers, dolibarr"
            echo ""
            echo "  Inventaire global (all) :"
            echo "    - proxmox, vmware          : Tous les hosts d'un provider"
            echo "    - proxmox_prod, vmware_prod : Par environnement et provider"
            echo "    - prod, dev, databases     : Tous providers confondus"
            exit 0
            ;;
        *)
            echo -e "${RED}Option inconnue: $1${NC}"
            exit 1
            ;;
    esac
done

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}      ORCHESTRATION ANSIBLE${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Construire la commande ansible-playbook
ANSIBLE_CMD="ansible-playbook -i $INVENTORY_FILE $ORCHESTRATE_PLAYBOOK"

if [ -n "$LIMIT" ]; then
    ANSIBLE_CMD="$ANSIBLE_CMD --limit $LIMIT"
    echo -e "${YELLOW}🎯 Limite: $LIMIT${NC}"
fi

if [ -n "$TAGS" ]; then
    ANSIBLE_CMD="$ANSIBLE_CMD --tags $TAGS"
    echo -e "${YELLOW}🏷️  Tags: $TAGS${NC}"
fi

if [ -n "$SKIP_TAGS" ]; then
    ANSIBLE_CMD="$ANSIBLE_CMD --skip-tags $SKIP_TAGS"
    echo -e "${YELLOW}⏭️  Skip tags: $SKIP_TAGS${NC}"
fi

if [ -n "$EXTRA_VARS" ]; then
    ANSIBLE_CMD="$ANSIBLE_CMD -e '$EXTRA_VARS'"
    echo -e "${YELLOW}📝 Variables: $EXTRA_VARS${NC}"
fi

if [ "$CHECK_MODE" = true ]; then
    ANSIBLE_CMD="$ANSIBLE_CMD --check"
    echo -e "${YELLOW}🔍 Mode: Dry-run (aucun changement)${NC}"
fi

echo ""
echo -e "${CYAN}Commande: $ANSIBLE_CMD${NC}"
echo ""

# Exécuter
eval $ANSIBLE_CMD

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ Configuration terminée${NC}"
echo -e "${GREEN}========================================${NC}"
