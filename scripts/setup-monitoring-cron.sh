#!/bin/bash
# Script pour configurer automatiquement le monitoring cron
# Ajoute les tâches cron pour le monitoring automatique

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

readonly MONITORING_DIR="$PROJECT_ROOT/monitoring"
readonly CRON_TMP=$(mktemp)

# Couleurs
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
}

# Générer les entrées cron
generate_cron_entries() {
    cat <<EOF
# Monitoring Git Mirror v2.0.0
# Ajouté automatiquement le $(date +%Y-%m-%d)

# Collecte quotidienne de métriques (à 2h du matin)
0 2 * * * $MONITORING_DIR/collect-metrics.sh >> $MONITORING_DIR/metrics.log 2>&1

# Génération hebdomadaire de rapports (lundi à 8h)
0 8 * * 1 $MONITORING_DIR/generate-report.sh >> $MONITORING_DIR/reports.log 2>&1

# Analyse de couverture hebdomadaire (dimanche à 23h)
0 23 * * 0 cd $PROJECT_ROOT && bash scripts/analyze-coverage.sh >> $MONITORING_DIR/coverage.log 2>&1

EOF
}

# Vérifier les scripts
check_scripts() {
    log_info "Vérification des scripts..."
    
    local errors=0
    
    if [ ! -x "$MONITORING_DIR/collect-metrics.sh" ]; then
        log_warning "collect-metrics.sh non exécutable"
        chmod +x "$MONITORING_DIR/collect-metrics.sh"
    fi
    
    if [ ! -x "$MONITORING_DIR/generate-report.sh" ]; then
        log_warning "generate-report.sh non exécutable"
        chmod +x "$MONITORING_DIR/generate-report.sh"
    fi
    
    log_success "Scripts vérifiés"
}

# Installer les tâches cron
install_cron() {
    log_info "Installation des tâches cron..."
    
    # Récupérer le crontab actuel
    crontab -l > "$CRON_TMP" 2>/dev/null || true
    
    # Vérifier si les entrées existent déjà
    if grep -q "Monitoring Git Mirror v2.0.0" "$CRON_TMP" 2>/dev/null; then
        log_warning "Les tâches cron existent déjà"
        log_info "Afficher les tâches actuelles:"
        grep "Monitoring Git Mirror" "$CRON_TMP" -A 10 || true
        return 0
    fi
    
    # Ajouter les nouvelles entrées
    generate_cron_entries >> "$CRON_TMP"
    
    # Installer le nouveau crontab
    if crontab "$CRON_TMP"; then
        log_success "✅ Tâches cron installées"
        
        log_info "Tâches ajoutées:"
        generate_cron_entries | grep -v "^#" | grep -v "^$" | sed 's/^/  /'
        
        return 0
    else
        log_error "Échec de l'installation du crontab"
        return 1
    fi
}

# Afficher les instructions manuelles
show_manual_instructions() {
    cat <<EOF

${YELLOW}=== Installation Manuelle ===${NC}

Si l'installation automatique échoue, ajoutez manuellement:

${BLUE}crontab -e${NC}

Puis copiez-collez:

$(generate_cron_entries)

${GREEN}=== Vérification ===${NC}

Vérifier les tâches cron installées:
${BLUE}crontab -l | grep "Monitoring Git Mirror"${NC}

Tester manuellement:
${BLUE}$MONITORING_DIR/collect-metrics.sh${NC}

Consulter les logs:
${BLUE}tail -f $MONITORING_DIR/metrics.log${NC}

EOF
}

# Fonction principale
main() {
    log_info "=== Configuration Monitoring Cron ==="
    echo ""
    
    check_scripts
    
    echo ""
    
    if install_cron; then
        echo ""
        log_success "=== Monitoring Cron Configuré ==="
        log_info "Les métriques seront collectées automatiquement"
    else
        echo ""
        log_warning "Installation automatique échouée"
        show_manual_instructions
    fi
    
    rm -f "$CRON_TMP"
}

main "$@"
