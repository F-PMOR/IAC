#!/bin/bash
# Script de déploiement Terraform
# Gère la création/mise à jour des VMs via Terraform

set -e

# Variables
PROJECT_ROOT="/root"
CONFIG_DIR="${PROJECT_ROOT}/config"
TERRAFORM_DIR="${PROJECT_ROOT}/terraform"
CSV_FILE="${CONFIG_DIR}/vms.csv"
CONFIG_FILE="${CONFIG_DIR}/vms-config.yml"
TF_FILE="${TERRAFORM_DIR}/vms-from-config-proxmox.tf"
TEMPLATE_FILE="${CONFIG_DIR}/vms-terraform.tf.j2"

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

Script de déploiement Terraform pour les VMs Proxmox

OPTIONS:
    -p, --plan-only           Génère le plan Terraform sans appliquer
    -a, --auto-apply          Applique automatiquement le plan Terraform
    -d, --destroy <vm_name>   Supprime une VM spécifique
    -f, --force               Force l'opération sans demander confirmation (avec --destroy)
    -h, --help                Affiche cette aide

EXEMPLES:
    $(basename "$0") --plan-only                      # Génère uniquement le plan
    $(basename "$0") --auto-apply                     # Déploie automatiquement les VMs
    $(basename "$0") --destroy dolibarr-dev01         # Supprime la VM (avec confirmation)
    $(basename "$0") --destroy dolibarr-dev01 --force # Supprime la VM sans confirmation
    $(basename "$0")                                  # Plan uniquement (par défaut)

EOF
}

# Parse arguments
AUTO_APPLY=false
PLAN_ONLY=true
DESTROY_MODE=false
VM_TO_DESTROY=""
FORCE_MODE=false
NO_REFRESH=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -a|--auto-apply)
            AUTO_APPLY=true
            PLAN_ONLY=false
            shift
            ;;
        -p|--plan-only)
            PLAN_ONLY=true
            AUTO_APPLY=false
            shift
            ;;
        --no-refresh)
            NO_REFRESH=true
            shift
            ;;
        -d|--destroy)
            if [ -z "$2" ] || [[ "$2" == -* ]]; then
                log_error "L'option --destroy nécessite un nom de VM"
                show_help
                exit 1
            fi
            DESTROY_MODE=true
            VM_TO_DESTROY="$2"
            shift 2
            ;;
        -f|--force)
            FORCE_MODE=true
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

# Étape 1: Vérification du fichier CSV
log_info "Vérification du fichier CSV..."
if [ ! -f "$CSV_FILE" ]; then
    log_error "Fichier CSV introuvable: $CSV_FILE"
    exit 1
fi
log_success "Fichier CSV trouvé"

# Mode destruction d'une VM spécifique
if [ "$DESTROY_MODE" = true ]; then
    log_warning "Mode destruction activé pour la VM: $VM_TO_DESTROY"
    
    # Conversion du nom de VM avec underscores pour Terraform
    VM_KEY=$(echo "$VM_TO_DESTROY" | tr '-' '_')
    
    # Initialisation Terraform
    log_info "Initialisation de Terraform..."
    cd "$TERRAFORM_DIR"
    tofu init > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        log_error "Échec de l'initialisation Terraform"
        exit 1
    fi
    log_success "Terraform initialisé"
    
    # Vérifier que la VM existe dans le state
    log_info "Vérification de l'existence de la VM dans le state Terraform..."
    if ! tofu state list | grep -q "proxmox_virtual_environment_vm.vms_csv\[\"$VM_KEY\"\]"; then
        log_error "VM '$VM_TO_DESTROY' (clé: $VM_KEY) non trouvée dans le state Terraform"
        log_info "VMs disponibles dans le state:"
        tofu state list | grep "proxmox_virtual_environment_vm.vms_csv" | sed 's/.*\["\(.*\)"\]/  - \1/' | tr '_' '-'
        exit 1
    fi
    
    # Confirmation
    if [ "$FORCE_MODE" = false ]; then
        echo ""
        log_warning "⚠️  ATTENTION: Vous êtes sur le point de SUPPRIMER la VM: $VM_TO_DESTROY"
        log_warning "⚠️  Cette action est IRRÉVERSIBLE!"
        echo ""
        read -p "Êtes-vous sûr? (tapez 'oui' pour confirmer): " confirmation
        
        if [ "$confirmation" != "oui" ]; then
            log_info "Suppression annulée"
            exit 0
        fi
    else
        log_info "Mode force activé - suppression sans confirmation"
    fi
    
    # Destruction de la VM
    log_info "Destruction de la VM $VM_TO_DESTROY..."
    tofu destroy -target="proxmox_virtual_environment_vm.vms_csv[\"$VM_KEY\"]" \
                 -target="proxmox_virtual_environment_file.user_config_csv[\"$VM_KEY\"]" \
                 -auto-approve
    
    if [ $? -ne 0 ]; then
        log_error "Échec de la destruction de la VM"
        exit 1
    fi
    
    log_success "VM $VM_TO_DESTROY supprimée avec succès!"
    
    # Nettoyage de l'inventaire Ansible
    INVENTORY_FILE="${PROJECT_ROOT}/ansible/inventory/proxmox/inventory.ini"
    if [ -f "$INVENTORY_FILE" ]; then
        log_info "Nettoyage de l'inventaire Ansible..."
        # Supprimer la ligne de la VM de l'inventaire
        sed -i.bak "/$VM_TO_DESTROY/d" "$INVENTORY_FILE" && rm "${INVENTORY_FILE}.bak"
        log_success "Inventaire Ansible mis à jour"
    fi
    
    echo ""
    echo "=========================================="
    echo "        VM SUPPRIMÉE AVEC SUCCÈS"
    echo "=========================================="
    echo ""
    echo "VM supprimée: $VM_TO_DESTROY"
    echo ""
    echo "⚠️  N'oubliez pas de:"
    echo "  1. Supprimer la ligne correspondante dans $CSV_FILE"
    echo "  2. Regénérer la configuration: ./deploy-terraform.sh --plan-only"
    echo ""
    echo "=========================================="
    
    exit 0
fi

# Étape 2: Conversion CSV vers YAML
log_info "Conversion du CSV vers la configuration YAML..."
cd "$CONFIG_DIR"
python3 csv-to-config.py
if [ $? -ne 0 ]; then
    log_error "Échec de la conversion CSV"
    exit 1
fi
log_success "Configuration YAML générée: $CONFIG_FILE"

# Étape 3: Génération des fichiers Terraform
log_info "Génération des fichiers Terraform à partir des templates..."
if [ ! -f "$TEMPLATE_FILE" ]; then
    log_error "Template Jinja2 Proxmox introuvable: $TEMPLATE_FILE"
    exit 1
fi

# Utilisation de Python pour rendre les templates Jinja2
python3 - <<PYTHON_SCRIPT
import yaml
from jinja2 import Environment, FileSystemLoader

# Chargement de la configuration
with open('${CONFIG_FILE}', 'r') as f:
    config = yaml.safe_load(f)

# Chargement et rendu du template Proxmox
env = Environment(loader=FileSystemLoader('${CONFIG_DIR}'))

# Générer vms-from-config.tf (Proxmox)
template_proxmox = env.get_template('vms-terraform.tf.j2')
output_proxmox = template_proxmox.render(config)
with open('${TF_FILE}', 'w') as f:
    f.write(output_proxmox)

# Générer vms-from-config-vmware.tf (VMware) si le template existe
try:
    template_vmware = env.get_template('vms-vmware.tf.j2')
    output_vmware = template_vmware.render(config)
    with open('${TERRAFORM_DIR}/vms-from-config-vmware.tf', 'w') as f:
        f.write(output_vmware)
    print("Fichiers Terraform générés avec succès (Proxmox + VMware)")
except:
    print("Fichier Terraform Proxmox généré avec succès")
PYTHON_SCRIPT

if [ $? -ne 0 ]; then
    log_error "Échec de la génération du fichier Terraform"
    exit 1
fi
log_success "Fichier Terraform généré: $TF_FILE"

# Étape 4: Initialisation Terraform
log_info "Initialisation de Terraform..."
cd "$TERRAFORM_DIR"
tofu init > /dev/null 2>&1
if [ $? -ne 0 ]; then
    log_error "Échec de l'initialisation Terraform"
    exit 1
fi
log_success "Terraform initialisé"

# Étape 5: Plan Terraform
log_info "Génération du plan Terraform..."
if [ "$NO_REFRESH" = true ]; then
    tofu plan -out=tfplan -parallelism=10 -refresh=false
else
    tofu plan -out=tfplan -parallelism=10 -refresh=true
fi
if [ $? -ne 0 ]; then
    log_error "Échec de la génération du plan"
    exit 1
fi

# Capture des VMs qui seront créées
NEWLY_CREATED=$(tofu show tfplan | grep "will be created" | grep "proxmox_virtual_environment_vm.vms_csv" | sed 's/.*vms_csv\["\([^"]*\)"\].*/\1/' || true)
if [ -n "$NEWLY_CREATED" ]; then
    log_info "VMs qui seront créées:"
    echo "$NEWLY_CREATED" | while read vm; do
        echo "  - $vm"
    done
    # Sauvegarde de la liste pour Ansible
    echo "$NEWLY_CREATED" > "${CONFIG_DIR}/newly-created-vms.txt"
else
    log_warning "Aucune nouvelle VM à créer"
    echo -n "" > "${CONFIG_DIR}/newly-created-vms.txt"
fi

log_success "Plan Terraform généré: tfplan"

# Étape 6: Application du plan (si demandé)
if [ "$AUTO_APPLY" = true ]; then
    log_info "Application du plan Terraform (parallelism=10)..."
    tofu apply -parallelism=10 -auto-approve tfplan
    
    if [ $? -ne 0 ]; then
        log_error "Échec de l'application Terraform"
        exit 1
    fi
    
    log_success "VMs déployées avec succès!"
    
    # Attente que les VMs soient prêtes
    if [ -s "${CONFIG_DIR}/newly-created-vms.txt" ]; then
        log_info "Attente de 30 secondes pour le démarrage des VMs et cloud-init..."
        sleep 30
        log_success "VMs prêtes pour la configuration Ansible"
    fi
else
    log_warning "Plan généré uniquement. Pour appliquer, utilisez: $0 --auto-apply"
fi

# Résumé
echo ""
echo "=========================================="
echo "           RÉSUMÉ TERRAFORM"
echo "=========================================="
echo ""
if [ "$AUTO_APPLY" = true ]; then
    echo "✅ VMs déployées avec succès"
    echo ""
    echo "Prochaine étape:"
    echo "  ${PROJECT_ROOT}/scripts/deploy-ansible.sh"
else
    echo "📋 Plan Terraform généré"
    echo ""
    echo "Prochaines étapes:"
    echo "  1. Appliquer: $0 --auto-apply"
    echo "  2. Configurer: ${PROJECT_ROOT}/scripts/deploy-ansible.sh"
fi
echo ""
echo "=========================================="
