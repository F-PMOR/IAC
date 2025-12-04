#!/bin/bash

###############################################################################
# Script: deploy-ansible.sh
# Description: Lance l'orchestrateur Ansible de manière native
# Usage: ./scripts/deploy-ansible.sh [options]
# Best usage : 
#  ./deploy-ansible.sh -l prod -t post-install, mysql  # installe les post-install et mysql sur les VMs de prod
#  ./deploy-ansible.sh -l dev -t post-install, dolibarr  # installe les post-install et dolibarr sur les VMs de dev
#  ./deploy-ansible.sh -l dolibarr-dev01 -t post-install, dolibarr  # installe les post-install et dolibarr sur dolibarr-dev01
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
            echo "Tags disponibles:"
            echo "  - post-install : Post-installation système"
            echo "  - mysql, databases : Configuration MySQL/MariaDB"
            echo "  - dolibarr, web : Déploiement Dolibarr"
            echo ""
            echo "Groupes disponibles:"
            echo "  - all : Toutes les VMs"
            echo "  - prod : VMs de production"
            echo "  - preprod : VMs de pré-production"
            echo "  - dev : VMs de développement"
            echo "  - databases : Serveurs de bases de données"
            echo "  - webservers : Serveurs web"
            echo "  - dolibarr : Serveurs Dolibarr"
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
