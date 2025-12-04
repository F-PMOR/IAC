#!/bin/bash
# Script orchestrateur principal
# Déploie l'infrastructure complète: Terraform + Ansible

set -e

# Variables
PROJECT_ROOT="/root"
SCRIPTS_DIR="${PROJECT_ROOT}/scripts"
TF_SCRIPT="${SCRIPTS_DIR}/deploy-terraform.sh"
ANSIBLE_SCRIPT="${SCRIPTS_DIR}/deploy-ansible.sh"

# Couleurs pour l'output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
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

log_step() {
    echo -e "${MAGENTA}[STEP]${NC} $1"
}

# Fonction d'aide
show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Script orchestrateur pour le déploiement complet de l'infrastructure

OPTIONS:
    -t, --terraform-only    Déploie uniquement avec Terraform (sans configuration Ansible)
    -a, --ansible-only      Configure uniquement avec Ansible (VMs déjà créées)
    -l, --limit GROUP       Limite Ansible à un groupe/host spécifique (prod, preprod, dev, etc.)
    --tags TAGS             Filtre Ansible par tags (post-install, mysql, dolibarr, etc.)
    --skip-tags TAGS        Exclut certains tags Ansible
    --plan-only             Génère uniquement le plan Terraform (sans apply)
    --check                 Mode dry-run pour Ansible (test sans modification)
    -h, --help              Affiche cette aide

EXEMPLES:
    # Déploiement complet (Terraform + Ansible, toutes les VMs)
    $(basename "$0")
    
    # Déploiement complet (environnement dev uniquement)
    $(basename "$0") --limit dev
    
    # Terraform uniquement (création VMs)
    $(basename "$0") --terraform-only
    
    # Ansible uniquement (configuration VMs existantes)
    $(basename "$0") --ansible-only
    
    # Ansible uniquement sur prod, déploiement Dolibarr seulement
    $(basename "$0") --ansible-only --limit prod --tags dolibarr
    
    # Plan Terraform uniquement (sans création ni configuration)
    $(basename "$0") --plan-only
    
    # Dry-run complet
    $(basename "$0") --check

GROUPES DISPONIBLES (--limit):
    - all, prod, preprod, dev
    - databases, webservers, dolibarr
    - Ou un nom de VM spécifique (ex: dolibarr-dev01)

TAGS DISPONIBLES (--tags):
    - post-install : Post-installation système
    - mysql        : Configuration MySQL/MariaDB
    - dolibarr     : Déploiement Dolibarr
    - databases    : Alias pour mysql
    - web          : Alias pour dolibarr

WORKFLOW:
    1. CSV → YAML (conversion configuration)
    2. YAML → Terraform (génération .tf)
    3. Terraform init + plan
    4. Terraform apply (création VMs)
    5. Attente cloud-init (30s)
    6. Ansible (configuration VMs via orchestrate.yml)

EOF
}

# Parse arguments
TERRAFORM_ONLY=false
ANSIBLE_ONLY=false
PLAN_ONLY=false
ANSIBLE_LIMIT=""
ANSIBLE_TAGS=""
ANSIBLE_SKIP_TAGS=""
ANSIBLE_CHECK=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--terraform-only)
            TERRAFORM_ONLY=true
            shift
            ;;
        -a|--ansible-only)
            ANSIBLE_ONLY=true
            shift
            ;;
        -l|--limit)
            ANSIBLE_LIMIT="--limit $2"
            shift 2
            ;;
        --tags)
            ANSIBLE_TAGS="--tags $2"
            shift 2
            ;;
        --skip-tags)
            ANSIBLE_SKIP_TAGS="--skip-tags $2"
            shift 2
            ;;
        --plan-only)
            PLAN_ONLY=true
            TERRAFORM_ONLY=true
            shift
            ;;
        --check)
            ANSIBLE_CHECK="--check"
            shift
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

# Vérifications
if [ "$TERRAFORM_ONLY" = true ] && [ "$ANSIBLE_ONLY" = true ]; then
    log_error "Options incompatibles: --terraform-only et --ansible-only"
    exit 1
fi

if [ ! -x "$TF_SCRIPT" ]; then
    log_error "Script Terraform introuvable ou non exécutable: $TF_SCRIPT"
    exit 1
fi

if [ ! -x "$ANSIBLE_SCRIPT" ]; then
    log_error "Script Ansible introuvable ou non exécutable: $ANSIBLE_SCRIPT"
    exit 1
fi

# Affichage du banner
echo ""
echo "=========================================="
echo "     DÉPLOIEMENT INFRASTRUCTURE"
echo "=========================================="
echo ""

# Étape 1: Terraform
if [ "$ANSIBLE_ONLY" = false ]; then
    log_step "ÉTAPE 1/2: Déploiement Terraform"
    echo ""
    
    if [ "$PLAN_ONLY" = true ]; then
        bash "$TF_SCRIPT" --plan-only
    else
        bash "$TF_SCRIPT" --auto-apply
    fi
    
    if [ $? -ne 0 ]; then
        log_error "Échec du déploiement Terraform"
        exit 1
    fi
    
    log_success "Terraform terminé"
    echo ""
fi

# Étape 2: Ansible
if [ "$TERRAFORM_ONLY" = false ]; then
    log_step "ÉTAPE 2/2: Configuration Ansible"
    echo ""
    
    # Construire la commande Ansible avec les options
    ANSIBLE_ARGS="$ANSIBLE_LIMIT $ANSIBLE_TAGS $ANSIBLE_SKIP_TAGS $ANSIBLE_CHECK"
    
    if [ -n "$ANSIBLE_LIMIT" ]; then
        log_info "Limite aux hôtes/groupes: $(echo $ANSIBLE_LIMIT | cut -d' ' -f2)"
    fi
    if [ -n "$ANSIBLE_TAGS" ]; then
        log_info "Tags sélectionnés: $(echo $ANSIBLE_TAGS | cut -d' ' -f2)"
    fi
    if [ -n "$ANSIBLE_SKIP_TAGS" ]; then
        log_info "Tags exclus: $(echo $ANSIBLE_SKIP_TAGS | cut -d' ' -f2)"
    fi
    if [ -n "$ANSIBLE_CHECK" ]; then
        log_warning "Mode DRY-RUN activé (aucune modification réelle)"
    fi
    
    bash "$ANSIBLE_SCRIPT" $ANSIBLE_ARGS
    
    if [ $? -ne 0 ]; then
        log_error "Échec de la configuration Ansible"
        exit 1
    fi
    
    log_success "Ansible terminé"
    echo ""
fi

# Résumé final
echo ""
echo "=========================================="
echo "         DÉPLOIEMENT TERMINÉ"
echo "=========================================="
echo ""

if [ "$PLAN_ONLY" = true ]; then
    echo "📋 Plan Terraform généré"
    echo ""
    echo "Pour appliquer:"
    echo "  bash ${SCRIPTS_DIR}/deploy-terraform.sh --auto-apply"
    echo "  bash ${SCRIPTS_DIR}/deploy-ansible.sh"
elif [ "$TERRAFORM_ONLY" = true ]; then
    echo "✅ VMs créées avec Terraform"
    echo ""
    echo "Pour configurer:"
    echo "  bash ${SCRIPTS_DIR}/deploy-ansible.sh"
elif [ "$ANSIBLE_ONLY" = true ]; then
    echo "✅ VMs configurées avec Ansible"
else
    echo "✅ Infrastructure complète déployée et configurée"
fi

echo ""
echo "Commandes utiles:"
echo "  - Déploiement complet:           bash $0"
echo "  - Déploiement dev uniquement:    bash $0 --limit dev"
echo "  - Terraform seulement:           bash $0 --terraform-only"
echo "  - Ansible seulement:             bash $0 --ansible-only"
echo "  - Dolibarr sur prod uniquement:  bash $0 --ansible-only --limit prod --tags dolibarr"
echo "  - Plan Terraform seulement:      bash $0 --plan-only"
echo "  - Dry-run complet:               bash $0 --check"
echo ""
echo "=========================================="
