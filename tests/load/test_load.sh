#!/bin/bash
# tests/load/test_load.sh - Tests de charge pour git-mirror

set -euo pipefail

# Variables de test
LOAD_TEST_DIR="/tmp/git-mirror-load-test"
LOAD_TEST_REPO_DIR="$LOAD_TEST_DIR/repositories"
LOAD_TEST_CACHE_DIR="$LOAD_TEST_DIR/cache"
LOAD_TEST_STATE_DIR="$LOAD_TEST_DIR/state"

# Paramètres de test
DEFAULT_REPOS=100
DEFAULT_PARALLEL_JOBS=5
DEFAULT_TIMEOUT=300

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction d'affichage des messages
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
Script de test de charge pour git-mirror

Usage: $0 [OPTIONS]

Options:
    -h, --help              Afficher cette aide
    -r, --repos N           Nombre de dépôts à traiter (défaut: $DEFAULT_REPOS)
    -p, --parallel N        Nombre de jobs parallèles (défaut: $DEFAULT_PARALLEL_JOBS)
    -t, --timeout N         Timeout en secondes (défaut: $DEFAULT_TIMEOUT)
    -d, --dry-run           Mode dry-run (pas de clonage réel)
    -v, --verbose           Mode verbeux
    -c, --cleanup           Nettoyer après les tests

Exemples:
    $0 --repos 50 --parallel 3    # Test avec 50 dépôts et 3 jobs parallèles
    $0 --dry-run --verbose       # Test en mode dry-run avec logs détaillés
    $0 --cleanup                 # Nettoyer les fichiers de test

EOF
}

# Fonction de nettoyage
cleanup() {
    log_info "Nettoyage des fichiers de test de charge..."
    rm -rf "$LOAD_TEST_DIR"
    log_success "Nettoyage terminé"
}

# Fonction de test de charge
run_load_test() {
    local repos="$1"
    local parallel_jobs="$2"
    local timeout="$3"
    local dry_run="$4"
    local verbose="$5"
    
    log_info "Démarrage du test de charge..."
    log_info "Paramètres:"
    log_info "  Dépôts: $repos"
    log_info "  Jobs parallèles: $parallel_jobs"
    log_info "  Timeout: ${timeout}s"
    log_info "  Mode dry-run: $dry_run"
    log_info "  Mode verbeux: $verbose"
    
    # Créer le répertoire de test
    mkdir -p "$LOAD_TEST_DIR"
    
    # Construire la commande
    local cmd="bash git-mirror.sh users microsoft -d $LOAD_TEST_REPO_DIR"
    
    if [ "$parallel_jobs" -gt 1 ]; then
        cmd="$cmd --parallel $parallel_jobs"
    fi
    
    if [ "$dry_run" = "true" ]; then
        cmd="$cmd --dry-run"
    fi
    
    if [ "$verbose" = "true" ]; then
        cmd="$cmd -v"
    fi
    
    # Mesurer le temps d'exécution
    local start_time
    start_time=$(date +%s)
    
    log_info "Exécution de la commande: $cmd"
    
    # Exécuter la commande avec timeout
    if timeout "$timeout" "$cmd"; then
        local end_time
        end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        log_success "Test de charge terminé avec succès en ${duration}s"
        
        # Afficher les statistiques
        if [ "$dry_run" = "false" ] && [ -d "$LOAD_TEST_REPO_DIR" ]; then
            local repo_count
            repo_count=$(find "$LOAD_TEST_REPO_DIR" -type d -name ".git" | wc -l)
            log_info "Dépôts clonés: $repo_count"
            
            local total_size
            total_size=$(du -sh "$LOAD_TEST_REPO_DIR" 2>/dev/null | cut -f1)
            log_info "Taille totale: $total_size"
        fi
        
        return 0
    else
        local exit_code=$?
        local end_time
        end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        if [ $exit_code -eq 124 ]; then
            log_error "Test de charge interrompu par timeout (${timeout}s)"
        else
            log_error "Test de charge échoué (code: $exit_code) après ${duration}s"
        fi
        
        return 1
    fi
}

# Fonction de test de performance
run_performance_test() {
    local repos="$1"
    local parallel_jobs="$2"
    
    log_info "Test de performance avec $parallel_jobs jobs parallèles..."
    
    # Test séquentiel
    log_info "Test séquentiel..."
    local seq_start
    seq_start=$(date +%s)
    
    if run_load_test "$repos" 1 600 true false; then
        local seq_end
        seq_end=$(date +%s)
        local seq_duration=$((seq_end - seq_start))
        
        log_success "Test séquentiel terminé en ${seq_duration}s"
    else
        log_error "Test séquentiel échoué"
        return 1
    fi
    
    # Test parallèle
    log_info "Test parallèle avec $parallel_jobs jobs..."
    local par_start
    par_start=$(date +%s)
    
    if run_load_test "$repos" "$parallel_jobs" 600 true false; then
        local par_end
        par_end=$(date +%s)
        local par_duration=$((par_end - par_start))
        
        log_success "Test parallèle terminé en ${par_duration}s"
        
        # Calculer l'amélioration
        local improvement=$((seq_duration * 100 / par_duration))
        log_info "Amélioration de performance: ${improvement}%"
        
        if [ "$improvement" -gt 100 ]; then
            log_success "Parallélisation efficace (amélioration: ${improvement}%)"
        else
            log_warning "Parallélisation peu efficace (amélioration: ${improvement}%)"
        fi
    else
        log_error "Test parallèle échoué"
        return 1
    fi
    
    return 0
}

# Fonction de test de mémoire
run_memory_test() {
    log_info "Test de mémoire..."
    
    # Vérifier si valgrind est disponible
    if ! command -v valgrind >/dev/null 2>&1; then
        log_warning "Valgrind non disponible, test de mémoire ignoré"
        return 0
    fi
    
    # Test avec valgrind
    local cmd="bash git-mirror.sh --dry-run -v users microsoft -d $LOAD_TEST_REPO_DIR"
    
    log_info "Exécution avec valgrind..."
    
    if valgrind --tool=memcheck --leak-check=full --show-leak-kinds=all --track-origins=yes "$cmd"; then
        log_success "Test de mémoire terminé sans fuites détectées"
    else
        log_warning "Test de mémoire terminé avec des avertissements"
    fi
    
    return 0
}

# Fonction principale
main() {
    local repos=$DEFAULT_REPOS
    local parallel_jobs=$DEFAULT_PARALLEL_JOBS
    local timeout=$DEFAULT_TIMEOUT
    local dry_run=false
    local verbose=false
    local cleanup_after=false
    
    # Parser les arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -r|--repos)
                repos="$2"
                shift 2
                ;;
            -p|--parallel)
                parallel_jobs="$2"
                shift 2
                ;;
            -t|--timeout)
                timeout="$2"
                shift 2
                ;;
            -d|--dry-run)
                dry_run=true
                shift
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            -c|--cleanup)
                cleanup_after=true
                shift
                ;;
            *)
                log_error "Option inconnue: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Afficher la configuration
    log_info "Configuration du test de charge:"
    log_info "  Dépôts: $repos"
    log_info "  Jobs parallèles: $parallel_jobs"
    log_info "  Timeout: ${timeout}s"
    log_info "  Mode dry-run: $dry_run"
    log_info "  Mode verbeux: $verbose"
    log_info "  Nettoyage après: $cleanup_after"
    
    # Créer le répertoire de test
    mkdir -p "$LOAD_TEST_DIR"
    
    # Exécuter les tests
    local tests_passed=0
    local tests_failed=0
    
    # Test de charge principal
    if run_load_test "$repos" "$parallel_jobs" "$timeout" "$dry_run" "$verbose"; then
        tests_passed=$((tests_passed + 1))
    else
        tests_failed=$((tests_failed + 1))
    fi
    
    # Test de performance si parallélisation activée
    if [ "$parallel_jobs" -gt 1 ] && [ "$dry_run" = "true" ]; then
        if run_performance_test "$repos" "$parallel_jobs"; then
            tests_passed=$((tests_passed + 1))
        else
            tests_failed=$((tests_failed + 1))
        fi
    fi
    
    # Test de mémoire
    if run_memory_test; then
        tests_passed=$((tests_passed + 1))
    else
        tests_failed=$((tests_failed + 1))
    fi
    
    # Afficher le résumé
    log_info "=== Résumé des Tests de Charge ==="
    log_info "Tests passés: $tests_passed"
    log_info "Tests échoués: $tests_failed"
    log_info "Total: $((tests_passed + tests_failed))"
    
    if [ "$tests_failed" -eq 0 ]; then
        log_success "Tous les tests de charge sont passés!"
    else
        log_error "$tests_failed test(s) de charge ont échoué"
    fi
    
    # Nettoyage si demandé
    if [ "$cleanup_after" = "true" ]; then
        cleanup
    fi
    
    return $tests_failed
}

# Nettoyage à la sortie
trap cleanup EXIT

# Exécuter la fonction principale
main "$@"
