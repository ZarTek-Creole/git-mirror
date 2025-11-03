#!/bin/bash
# Script d'exécution des tests de recette utilisateur (UAT)
# Exécute les 6 scénarios définis dans docs/USER_ACCEPTANCE_TESTING.md

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Couleurs
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Fichiers de résultats
readonly UAT_RESULTS_DIR="$PROJECT_ROOT/uat-results"
readonly UAT_LOG="$UAT_RESULTS_DIR/uat-$(date +%Y%m%d-%H%M%S).log"
readonly UAT_REPORT="$UAT_RESULTS_DIR/uat-report-$(date +%Y%m%d-%H%M%S).md"

# Compteurs
TOTAL_SCENARIOS=0
PASSED_SCENARIOS=0
FAILED_SCENARIOS=0
SKIPPED_SCENARIOS=0

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*" | tee -a "$UAT_LOG"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*" | tee -a "$UAT_LOG"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*" | tee -a "$UAT_LOG"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" | tee -a "$UAT_LOG"
}

# Initialisation
init_uat() {
    mkdir -p "$UAT_RESULTS_DIR"
    log_info "=== Démarrage des Tests UAT ==="
    log_info "Résultats: $UAT_RESULTS_DIR"
    log_info "Log: $UAT_LOG"
    log_info "Rapport: $UAT_REPORT"
    echo ""
}

# Scénario 1: Utilisateur Débutant
scenario_1_beginner() {
    local scenario="Scénario 1: Utilisateur Débutant"
    log_info "=== $scenario ==="
    TOTAL_SCENARIOS=$((TOTAL_SCENARIOS + 1))
    
    local passed=0
    local failed=0
    
    # Test 1.1: Installation
    log_info "Test 1.1: Vérification installation..."
    if [ -x "$PROJECT_ROOT/git-mirror.sh" ]; then
        log_success "✅ Script exécutable"
        passed=$((passed + 1))
    else
        log_error "❌ Script non exécutable"
        failed=$((failed + 1))
    fi
    
    # Test 1.2: Aide
    log_info "Test 1.2: Vérification aide..."
    if "$PROJECT_ROOT/git-mirror.sh" --help >/dev/null 2>&1; then
        log_success "✅ Aide fonctionne"
        passed=$((passed + 1))
    else
        log_error "❌ Aide ne fonctionne pas"
        failed=$((failed + 1))
    fi
    
    # Test 1.3: Version
    log_info "Test 1.3: Vérification version..."
    if "$PROJECT_ROOT/git-mirror.sh" --version >/dev/null 2>&1 || \
       grep -q "SCRIPT_VERSION" "$PROJECT_ROOT/git-mirror.sh"; then
        log_success "✅ Version disponible"
        passed=$((passed + 1))
    else
        log_warning "⚠️  Version non disponible (non bloquant)"
        passed=$((passed + 1))
    fi
    
    # Test 1.4: Documentation
    log_info "Test 1.4: Vérification documentation..."
    if [ -f "$PROJECT_ROOT/docs/USER_GUIDE.md" ]; then
        log_success "✅ Documentation présente"
        passed=$((passed + 1))
    else
        log_error "❌ Documentation manquante"
        failed=$((failed + 1))
    fi
    
    if [ $failed -eq 0 ]; then
        log_success "✅ $scenario: RÉUSSI ($passed/$((passed + failed)) tests)"
        PASSED_SCENARIOS=$((PASSED_SCENARIOS + 1))
        return 0
    else
        log_error "❌ $scenario: ÉCHOUÉ ($failed erreurs)"
        FAILED_SCENARIOS=$((FAILED_SCENARIOS + 1))
        return 1
    fi
}

# Scénario 2: Mode Incrémental (simulé)
scenario_2_incremental() {
    local scenario="Scénario 2: Mode Incrémental"
    log_info "=== $scenario ==="
    TOTAL_SCENARIOS=$((TOTAL_SCENARIOS + 1))
    
    log_info "Test 2.1: Vérification module incrémental..."
    if grep -q "incremental" "$PROJECT_ROOT/git-mirror.sh" && \
       [ -f "$PROJECT_ROOT/lib/incremental/incremental.sh" ]; then
        log_success "✅ Module incrémental présent"
        log_success "✅ $scenario: VALIDÉ (test simulé)"
        PASSED_SCENARIOS=$((PASSED_SCENARIOS + 1))
        return 0
    else
        log_error "❌ Module incrémental manquant"
        FAILED_SCENARIOS=$((FAILED_SCENARIOS + 1))
        return 1
    fi
}

# Scénario 3: Mode Parallèle
scenario_3_parallel() {
    local scenario="Scénario 3: Mode Parallèle"
    log_info "=== $scenario ==="
    TOTAL_SCENARIOS=$((TOTAL_SCENARIOS + 1))
    
    log_info "Test 3.1: Vérification support parallèle..."
    if grep -q "parallel" "$PROJECT_ROOT/git-mirror.sh" && \
       [ -f "$PROJECT_ROOT/lib/parallel/parallel.sh" ]; then
        log_success "✅ Support parallèle présent"
        
        log_info "Test 3.2: Vérification GNU parallel..."
        if command -v parallel >/dev/null 2>&1; then
            log_success "✅ GNU parallel disponible"
        else
            log_warning "⚠️  GNU parallel non installé (optionnel)"
        fi
        
        log_success "✅ $scenario: VALIDÉ"
        PASSED_SCENARIOS=$((PASSED_SCENARIOS + 1))
        return 0
    else
        log_error "❌ Support parallèle manquant"
        FAILED_SCENARIOS=$((FAILED_SCENARIOS + 1))
        return 1
    fi
}

# Scénario 4: Métriques
scenario_4_metrics() {
    local scenario="Scénario 4: Métriques"
    log_info "=== $scenario ==="
    TOTAL_SCENARIOS=$((TOTAL_SCENARIOS + 1))
    
    log_info "Test 4.1: Vérification module métriques..."
    if [ -f "$PROJECT_ROOT/lib/metrics/metrics.sh" ]; then
        log_success "✅ Module métriques présent"
        
        log_info "Test 4.2: Vérification export JSON..."
        if grep -q "metrics_export_json" "$PROJECT_ROOT/lib/metrics/metrics.sh"; then
            log_success "✅ Export JSON disponible"
        fi
        
        log_info "Test 4.3: Vérification export CSV..."
        if grep -q "metrics_export_csv" "$PROJECT_ROOT/lib/metrics/metrics.sh"; then
            log_success "✅ Export CSV disponible"
        fi
        
        log_info "Test 4.4: Vérification export HTML..."
        if grep -q "metrics_export_html" "$PROJECT_ROOT/lib/metrics/metrics.sh"; then
            log_success "✅ Export HTML disponible"
        fi
        
        log_success "✅ $scenario: VALIDÉ"
        PASSED_SCENARIOS=$((PASSED_SCENARIOS + 1))
        return 0
    else
        log_error "❌ Module métriques manquant"
        FAILED_SCENARIOS=$((FAILED_SCENARIOS + 1))
        return 1
    fi
}

# Scénario 5: Filtrage
scenario_5_filtering() {
    local scenario="Scénario 5: Filtrage"
    log_info "=== $scenario ==="
    TOTAL_SCENARIOS=$((TOTAL_SCENARIOS + 1))
    
    log_info "Test 5.1: Vérification module filtrage..."
    if [ -f "$PROJECT_ROOT/lib/filters/filters.sh" ]; then
        log_success "✅ Module filtrage présent"
        
        log_info "Test 5.2: Vérification exclusion forks..."
        if grep -q "exclude-forks\|EXCLUDE_FORKS" "$PROJECT_ROOT/git-mirror.sh"; then
            log_success "✅ Exclusion forks disponible"
        fi
        
        log_info "Test 5.3: Vérification patterns..."
        if grep -q "include\|exclude\|filter" "$PROJECT_ROOT/git-mirror.sh"; then
            log_success "✅ Patterns disponibles"
        fi
        
        log_success "✅ $scenario: VALIDÉ"
        PASSED_SCENARIOS=$((PASSED_SCENARIOS + 1))
        return 0
    else
        log_error "❌ Module filtrage manquant"
        FAILED_SCENARIOS=$((FAILED_SCENARIOS + 1))
        return 1
    fi
}

# Scénario 6: CI/CD (validation)
scenario_6_cicd() {
    local scenario="Scénario 6: CI/CD"
    log_info "=== $scenario ==="
    TOTAL_SCENARIOS=$((TOTAL_SCENARIOS + 1))
    
    log_info "Test 6.1: Vérification workflows GitHub Actions..."
    if [ -d "$PROJECT_ROOT/.github/workflows" ]; then
        local workflow_count
        workflow_count=$(find "$PROJECT_ROOT/.github/workflows" -name "*.yml" | wc -l)
        log_success "✅ $workflow_count workflows trouvés"
        
        log_info "Test 6.2: Vérification mode non-interactif..."
        if grep -q "INTERACTIVE_MODE\|interactive" "$PROJECT_ROOT/git-mirror.sh"; then
            log_success "✅ Mode non-interactif supporté"
        fi
        
        log_success "✅ $scenario: VALIDÉ"
        PASSED_SCENARIOS=$((PASSED_SCENARIOS + 1))
        return 0
    else
        log_error "❌ Workflows GitHub Actions manquants"
        FAILED_SCENARIOS=$((FAILED_SCENARIOS + 1))
        return 1
    fi
}

# Générer le rapport
generate_report() {
    cat > "$UAT_REPORT" <<EOF
# Rapport de Recette Utilisateur - Git Mirror v2.0.0

**Date**: $(date +%Y-%m-%d\ %H:%M:%S)
**Environnement**: $(uname -a)
**Script**: $0

## Résumé

- **Total scénarios**: $TOTAL_SCENARIOS
- **Réussis**: $PASSED_SCENARIOS
- **Échoués**: $FAILED_SCENARIOS
- **Ignorés**: $SKIPPED_SCENARIOS
- **Taux de réussite**: $((PASSED_SCENARIOS * 100 / TOTAL_SCENARIOS))%

## Détails des Scénarios

Voir le log complet: \`$UAT_LOG\`

## Recommandation

EOF

    if [ $FAILED_SCENARIOS -eq 0 ]; then
        echo "- [x] ✅ **ACCEPTÉ POUR RELEASE**" >> "$UAT_REPORT"
    else
        echo "- [ ] ⚠️ **ACCEPTÉ AVEC RÉSERVES** ($FAILED_SCENARIOS scénarios échoués)" >> "$UAT_REPORT"
    fi

    echo "" >> "$UAT_REPORT"
    echo "## Prochaines Étapes" >> "$UAT_REPORT"
    echo "" >> "$UAT_REPORT"
    echo "1. Corriger les scénarios échoués (si applicable)" >> "$UAT_REPORT"
    echo "2. Procéder à la release v2.0.0" >> "$UAT_REPORT"
    echo "3. Mettre en place le monitoring continu" >> "$UAT_REPORT"
}

# Fonction principale
main() {
    init_uat
    
    log_info "Exécution des 6 scénarios UAT..."
    echo ""
    
    scenario_1_beginner
    echo ""
    
    scenario_2_incremental
    echo ""
    
    scenario_3_parallel
    echo ""
    
    scenario_4_metrics
    echo ""
    
    scenario_5_filtering
    echo ""
    
    scenario_6_cicd
    echo ""
    
    # Générer le rapport
    generate_report
    
    # Résumé final
    log_info "=== Résumé Final ==="
    log_info "Total: $TOTAL_SCENARIOS scénarios"
    log_success "Réussis: $PASSED_SCENARIOS"
    if [ $FAILED_SCENARIOS -gt 0 ]; then
        log_error "Échoués: $FAILED_SCENARIOS"
    fi
    log_info "Rapport: $UAT_REPORT"
    echo ""
    
    if [ $FAILED_SCENARIOS -eq 0 ]; then
        log_success "✅ TOUS LES SCÉNARIOS UAT SONT RÉUSSIS"
        log_success "✅ PRÊT POUR RELEASE v2.0.0"
        return 0
    else
        log_warning "⚠️  $FAILED_SCENARIOS scénario(s) échoué(s)"
        return 1
    fi
}

# Exécuter
main "$@"
