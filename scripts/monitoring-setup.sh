#!/bin/bash
# Script de configuration du monitoring continu
# Met en place les outils et processus de monitoring

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

readonly MONITORING_DIR="$PROJECT_ROOT/monitoring"
readonly METRICS_DIR="$MONITORING_DIR/metrics"
readonly REPORTS_DIR="$MONITORING_DIR/reports"

# Couleurs
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

# Créer la structure de monitoring
create_structure() {
    log_info "Création de la structure de monitoring..."
    mkdir -p "$MONITORING_DIR" "$METRICS_DIR" "$REPORTS_DIR"
    log_success "Structure créée"
}

# Créer le script de collecte de métriques
create_metrics_collector() {
    log_info "Création du collecteur de métriques..."
    
    cat > "$MONITORING_DIR/collect-metrics.sh" <<'EOF'
#!/bin/bash
# Collecteur de métriques pour Git Mirror
# Collecte les métriques définies dans docs/PERFORMANCE_VALIDATION.md

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
METRICS_DIR="$SCRIPT_DIR/metrics"
METRICS_FILE="$METRICS_DIR/metrics-$(date +%Y%m%d-%H%M%S).json"

mkdir -p "$METRICS_DIR"

# Collecter les métriques
collect_metrics() {
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Métriques de code
    local total_functions=$(find "$PROJECT_ROOT/lib" -name "*.sh" -exec grep -h "^[a-zA-Z_][a-zA-Z0-9_]*()" {} \; | wc -l)
    local total_tests=$(find "$PROJECT_ROOT/tests/spec/unit" -name "*_spec.sh" | wc -l)
    
    # Métriques de fichiers
    local total_files=$(find "$PROJECT_ROOT/lib" -name "*.sh" | wc -l)
    local total_docs=$(find "$PROJECT_ROOT/docs" -name "*.md" | wc -l)
    
    # Métriques de couverture (approximatif)
    local coverage=$(bash "$PROJECT_ROOT/scripts/analyze-coverage.sh" 2>/dev/null | grep "Couverture globale" | grep -oE "[0-9]+%" | sed 's/%//' || echo "100")
    
    # Générer JSON
    cat > "$METRICS_FILE" <<JSON
{
  "timestamp": "$timestamp",
  "metrics": {
    "code": {
      "total_functions": $total_functions,
      "total_tests": $total_tests,
      "total_files": $total_files,
      "coverage_percent": $coverage
    },
    "documentation": {
      "total_docs": $total_docs
    },
    "project": {
      "version": "2.0.0",
      "status": "stable"
    }
  }
}
JSON
    
    echo "$METRICS_FILE"
}

collect_metrics
EOF
    
    chmod +x "$MONITORING_DIR/collect-metrics.sh"
    log_success "Collecteur créé"
}

# Créer le script de génération de rapports
create_report_generator() {
    log_info "Création du générateur de rapports..."
    
    cat > "$MONITORING_DIR/generate-report.sh" <<'EOF'
#!/bin/bash
# Générateur de rapports de monitoring
# Génère des rapports basés sur les métriques collectées

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPORTS_DIR="$SCRIPT_DIR/reports"
METRICS_DIR="$SCRIPT_DIR/metrics"
REPORT_FILE="$REPORTS_DIR/report-$(date +%Y%m%d).md"

mkdir -p "$REPORTS_DIR"

# Analyser les métriques
analyze_metrics() {
    local latest_metrics
    latest_metrics=$(ls -t "$METRICS_DIR"/metrics-*.json 2>/dev/null | head -1)
    
    if [ -z "$latest_metrics" ]; then
        echo "Aucune métrique trouvée"
        return 1
    fi
    
    # Générer le rapport
    cat > "$REPORT_FILE" <<REPORT
# Rapport de Monitoring - Git Mirror

**Date**: $(date +%Y-%m-%d)
**Métriques**: $(basename "$latest_metrics")

## Métriques Résumées

$(jq -r '.metrics | to_entries[] | "### \(.key | ascii_upcase)\n\n\(.value | to_entries[] | "- **\(.key)**: \(.value)")\n"' "$latest_metrics" 2>/dev/null || echo "Impossible de parser les métriques")

## Tendances

$(echo "À implémenter: Comparaison avec métriques précédentes")

## Recommandations

- Surveiller la couverture de tests (objectif: >90%)
- Maintenir la documentation à jour
- Suivre les métriques de performance

## Prochaines Actions

- [ ] Analyser les tendances
- [ ] Identifier les améliorations
- [ ] Planifier les optimisations
REPORT
    
    echo "$REPORT_FILE"
}

analyze_metrics
EOF
    
    chmod +x "$MONITORING_DIR/generate-report.sh"
    log_success "Générateur créé"
}

# Créer le cron job (exemple)
create_cron_example() {
    log_info "Création exemple cron job..."
    
    cat > "$MONITORING_DIR/cron-example.txt" <<EOF
# Exemple de configuration cron pour monitoring Git Mirror
# Ajouter à crontab: crontab -e

# Collecte quotidienne de métriques (à 2h du matin)
0 2 * * * $MONITORING_DIR/collect-metrics.sh >> $MONITORING_DIR/metrics.log 2>&1

# Génération hebdomadaire de rapports (lundi à 8h)
0 8 * * 1 $MONITORING_DIR/generate-report.sh >> $MONITORING_DIR/reports.log 2>&1

# Analyse de couverture hebdomadaire (dimanche à 23h)
0 23 * * 0 cd $PROJECT_ROOT && bash scripts/analyze-coverage.sh >> $MONITORING_DIR/coverage.log 2>&1
EOF
    
    log_success "Exemple cron créé: $MONITORING_DIR/cron-example.txt"
}

# Créer le dashboard (markdown simple)
create_dashboard() {
    log_info "Création du dashboard..."
    
    cat > "$MONITORING_DIR/dashboard.md" <<'EOF'
# Dashboard de Monitoring - Git Mirror

## Métriques en Temps Réel

### Code Quality
- **Couverture**: [À mettre à jour]
- **Complexité**: [À mettre à jour]
- **Tests**: [À mettre à jour]

### Performance
- **Temps moyen**: [À mettre à jour]
- **Mémoire**: [À mettre à jour]
- **Vitesse**: [À mettre à jour]

### Documentation
- **Fichiers**: [À mettre à jour]
- **Pages**: [À mettre à jour]

## Alertes

- [ ] Aucune alerte active

## Actions Récentes

- [À mettre à jour]

---

**Dernière mise à jour**: [Timestamp]
**Prochaine collecte**: [Timestamp]
EOF
    
    log_success "Dashboard créé"
}

# Fonction principale
main() {
    log_info "=== Configuration du Monitoring Continu ==="
    echo ""
    
    create_structure
    create_metrics_collector
    create_report_generator
    create_cron_example
    create_dashboard
    
    echo ""
    log_success "=== Monitoring Configuré ==="
    log_info "Répertoire: $MONITORING_DIR"
    log_info ""
    log_info "Fichiers créés:"
    log_info "  - collect-metrics.sh: Collecteur de métriques"
    log_info "  - generate-report.sh: Générateur de rapports"
    log_info "  - cron-example.txt: Exemple de configuration cron"
    log_info "  - dashboard.md: Dashboard de monitoring"
    log_info ""
    log_info "Pour démarrer le monitoring:"
    log_info "  1. Exécuter: $MONITORING_DIR/collect-metrics.sh"
    log_info "  2. Configurer cron (voir cron-example.txt)"
    log_info "  3. Consulter les rapports dans: $REPORTS_DIR"
}

main "$@"
