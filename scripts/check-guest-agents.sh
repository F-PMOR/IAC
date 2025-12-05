#!/bin/bash

###############################################################################
# Script: check-guest-agents.sh
# Description: Vérifie l'installation des guest agents sur les VMs
# Usage: ./scripts/check-guest-agents.sh [vm-name-or-group]
###############################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Chemins
ANSIBLE_DIR="${PROJECT_ROOT}/ansible"
INVENTORY_FILE="${INVENTORY_FILE:-${ANSIBLE_DIR}/inventory/proxmox/inventory.ini}"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

TARGET="${1:-all}"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   VÉRIFICATION GUEST AGENTS${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}Cible: ${TARGET}${NC}"
echo ""

# Vérification QEMU Guest Agent
echo -e "${BLUE}Vérification QEMU Guest Agent (Proxmox)...${NC}"
ansible $TARGET -i $INVENTORY_FILE -m shell -a "command -v qemu-ga || echo 'NOT_INSTALLED'" -b 2>/dev/null | grep -E "(SUCCESS|NOT_INSTALLED)" || true
echo ""

# Vérification VMware Tools
echo -e "${BLUE}Vérification VMware Tools (vSphere)...${NC}"
ansible $TARGET -i $INVENTORY_FILE -m shell -a "command -v vmware-toolbox-cmd || echo 'NOT_INSTALLED'" -b 2>/dev/null | grep -E "(SUCCESS|NOT_INSTALLED)" || true
echo ""

# Vérification des services
echo -e "${BLUE}Vérification des services...${NC}"
echo ""
echo -e "${YELLOW}QEMU Guest Agent:${NC}"
ansible $TARGET -i $INVENTORY_FILE -m systemd -a "name=qemu-guest-agent state=started" -b 2>/dev/null | grep -E "(SUCCESS|FAILED)" || echo "Service non trouvé"
echo ""

echo -e "${YELLOW}VMware Tools (vmtoolsd):${NC}"
ansible $TARGET -i $INVENTORY_FILE -m systemd -a "name=vmtoolsd state=started" -b 2>/dev/null | grep -E "(SUCCESS|FAILED)" || echo "Service non trouvé"
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Vérification terminée${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Pour installer les agents manquants :${NC}"
echo -e "  QEMU Agent:    ${BLUE}./scripts/deploy-ansible.sh --tags qemu-agent${NC}"
echo -e "  VMware Tools:  ${BLUE}./scripts/deploy-ansible.sh --tags vmware-tools${NC}"
echo -e "  Les deux:      ${BLUE}./scripts/deploy-ansible.sh --tags agent${NC}"
