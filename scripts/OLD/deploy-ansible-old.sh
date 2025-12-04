#!/bin/bash
# Script de configuration Ansible
# Configure les VMs après leur déploiement Terraform

set -e

# Variables
PROJECT_ROOT="/root"
ANSIBLE_DIR="${PROJECT_ROOT}/ansible"
CONFIG_DIR="${PROJECT_ROOT}/config"
PLAYBOOK="${ANSIBLE_DIR}/playbooks/configure-vms.yml"

# Couleurs pour l'output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction d'affichage
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Fonction d'aide
show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Script de configuration Ansible pour les VMs déployées

OPTIONS:
    -s, --skip-existing     Configure uniquement les nouvelles VMs (détectées par Terraform)
    -a, --all               Configure toutes les VMs (ignore le statut)
    -p, --parallel NUM      Nombre de VMs à configurer en parallèle (défaut: 3, max: 5)
    -h, --help              Affiche cette aide

EXEMPLES:
    $(basename "$0")                    # Configure toutes les VMs
    $(basename "$0") --skip-existing    # Configure uniquement les nouvelles VMs
    $(basename "$0") --parallel 5       # Configure avec 5 VMs en parallèle

EOF
}

# Parse arguments
SKIP_EXISTING=false
PARALLEL=3

while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--skip-existing)
            SKIP_EXISTING=true
            shift
            ;;
        -a|--all)
            SKIP_EXISTING=false
            shift
            ;;
        -p|--parallel)
            PARALLEL="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            log_error "Option inconnue: $1"
            show_help
            exit 1
            ;;
    esac
done

# Vérification du playbook
if [ ! -f "$PLAYBOOK" ]; then
    log_error "Playbook introuvable: $PLAYBOOK"
    exit 1
fi

# Affichage du mode
echo ""
echo "=========================================="
echo "      CONFIGURATION ANSIBLE"
echo "=========================================="
echo ""
log_info "Mode: $([ "$SKIP_EXISTING" = true ] && echo "Nouvelles VMs uniquement" || echo "Toutes les VMs")"
log_info "Parallélisme: $PARALLEL VMs à la fois"
echo ""

# Exécution du playbook Ansible
log_info "Lancement de la configuration Ansible..."
cd "$ANSIBLE_DIR"

if [ "$SKIP_EXISTING" = true ]; then
    ansible-playbook "$PLAYBOOK" \
        -e skip_existing_vms=true \
        -e ansible_parallel="$PARALLEL" \
        -i inventory/proxmox/inventory.ini
else
    ansible-playbook "$PLAYBOOK" \
        -e skip_existing_vms=false \
        -e ansible_parallel="$PARALLEL" \
        -i inventory/proxmox/inventory.ini
fi

if [ $? -ne 0 ]; then
    log_error "Échec de la configuration Ansible"
    exit 1
fi

log_success "Configuration Ansible terminée avec succès!"

# Résumé
echo ""
echo "=========================================="
echo "          CONFIGURATION TERMINÉE"
echo "=========================================="
echo ""
echo "✅ VMs configurées avec succès"
echo ""
echo "Pour mettre à jour une VM spécifique:"
echo "  ansible-playbook playbooks/post-installation.yml -l <vm-name> -i inventory/proxmox/inventory.ini"
echo ""
echo "=========================================="
