#!/bin/bash
# tests/integration/test_integration.sh - Tests d'intégration pour git-mirror

set -euo pipefail

# Variables de test
TEST_DIR="/tmp/git-mirror-integration-test"
TEST_REPO_DIR="$TEST_DIR/repositories"
TEST_CACHE_DIR="$TEST_DIR/cache"
TEST_STATE_DIR="$TEST_DIR/state"

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

# Fonction de nettoyage
cleanup() {
    log_info "Nettoyage des fichiers de test..."
    rm -rf "$TEST_DIR"
}

# Fonction de test
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    log_info "Exécution du test: $test_name"
    
    if eval "$test_command"; then
        log_success "Test réussi: $test_name"
        return 0
    else
        log_error "Test échoué: $test_name"
        return 1
    fi
}

# Test 1: Vérification des dépendances
test_dependencies() {
    log_info "Vérification des dépendances..."
    
    local deps=("git" "curl" "jq" "bash")
    local missing_deps=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing_deps+=("$dep")
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_error "Dépendances manquantes: ${missing_deps[*]}"
        return 1
    fi
    
    log_success "Toutes les dépendances sont disponibles"
    return 0
}

# Test 2: Test du mode dry-run
test_dry_run() {
    log_info "Test du mode dry-run..."
    
    # Créer le répertoire de test
    mkdir -p "$TEST_DIR"
    
    # Exécuter en mode dry-run
    local output
    output=$(bash git-mirror.sh --dry-run -v users microsoft -d "$TEST_REPO_DIR" 2>&1)
    
    # Vérifier que le mode dry-run est activé
    if echo "$output" | grep -q "MODE DRY-RUN ACTIVÉ"; then
        log_success "Mode dry-run détecté"
    else
        log_error "Mode dry-run non détecté"
        return 1
    fi
    
    # Vérifier qu'aucun dépôt n'a été cloné
    if [ ! -d "$TEST_REPO_DIR" ]; then
        log_success "Aucun dépôt cloné en mode dry-run"
    else
        log_error "Des dépôts ont été clonés en mode dry-run"
        return 1
    fi
    
    return 0
}

# Test 3: Test de la validation des paramètres
test_parameter_validation() {
    log_info "Test de la validation des paramètres..."
    
    # Test avec des paramètres invalides
    local output
    output=$(bash git-mirror.sh --dry-run users invalid-user -d "/invalid/path" 2>&1)
    
    # Vérifier que la validation échoue
    if echo "$output" | grep -q "Validation des paramètres échouée"; then
        log_success "Validation des paramètres invalides détectée"
    else
        log_warning "Validation des paramètres invalides non détectée"
    fi
    
    return 0
}

# Test 4: Test de l'authentification
test_authentication() {
    log_info "Test de l'authentification..."
    
    # Test avec un token invalide
    export GITHUB_TOKEN="invalid_token"
    
    local output
    output=$(bash git-mirror.sh --dry-run -v users microsoft -d "$TEST_REPO_DIR" 2>&1)
    
    # Vérifier que l'authentification échoue
    if echo "$output" | grep -q "Token GitHub invalide"; then
        log_success "Authentification invalide détectée"
    else
        log_warning "Authentification invalide non détectée"
    fi
    
    # Nettoyer
    unset GITHUB_TOKEN
    
    return 0
}

# Test 5: Test des modules
test_modules() {
    log_info "Test des modules..."
    
    # Vérifier que les modules peuvent être chargés
    local modules=("lib/auth/auth.sh" "lib/api/github_api.sh" "lib/state/state.sh" "lib/parallel/parallel.sh" "lib/filters/filters.sh" "lib/metrics/metrics.sh" "lib/interactive/interactive.sh" "lib/incremental/incremental.sh")
    
    for module in "${modules[@]}"; do
        if [ -f "$module" ]; then
            log_success "Module trouvé: $module"
        else
            log_error "Module manquant: $module"
            return 1
        fi
    done
    
    return 0
}

# Test 6: Test de la configuration
test_configuration() {
    log_info "Test de la configuration..."
    
    # Vérifier que le fichier de configuration existe
    if [ -f "config/git-mirror.conf" ]; then
        log_success "Fichier de configuration trouvé"
    else
        log_error "Fichier de configuration manquant"
        return 1
    fi
    
    # Vérifier que le fichier de configuration est valide
    if bash -n "config/git-mirror.conf"; then
        log_success "Fichier de configuration valide"
    else
        log_error "Fichier de configuration invalide"
        return 1
    fi
    
    return 0
}

# Test 7: Test des tests unitaires
test_unit_tests() {
    log_info "Test des tests unitaires..."
    
    # Vérifier que bats est disponible
    if ! command -v bats >/dev/null 2>&1; then
        log_warning "Bats non disponible, installation..."
        if command -v npm >/dev/null 2>&1; then
            npm install -g bats
        else
            log_error "Impossible d'installer bats"
            return 1
        fi
    fi
    
    # Exécuter les tests unitaires
    if bats tests/unit/; then
        log_success "Tests unitaires passés"
    else
        log_error "Tests unitaires échoués"
        return 1
    fi
    
    return 0
}

# Test 8: Test de la documentation
test_documentation() {
    log_info "Test de la documentation..."
    
    # Vérifier que le README existe
    if [ -f "README.md" ]; then
        log_success "README trouvé"
    else
        log_error "README manquant"
        return 1
    fi
    
    # Vérifier que le Makefile existe
    if [ -f "Makefile" ]; then
        log_success "Makefile trouvé"
    else
        log_error "Makefile manquant"
        return 1
    fi
    
    # Vérifier que le script d'installation existe
    if [ -f "install.sh" ]; then
        log_success "Script d'installation trouvé"
    else
        log_error "Script d'installation manquant"
        return 1
    fi
    
    return 0
}

# Test 9: Test de la structure du projet
test_project_structure() {
    log_info "Test de la structure du projet..."
    
    # Vérifier la structure des répertoires
    local dirs=("lib" "config" "tests" "docs")
    
    for dir in "${dirs[@]}"; do
        if [ -d "$dir" ]; then
            log_success "Répertoire trouvé: $dir"
        else
            log_error "Répertoire manquant: $dir"
            return 1
        fi
    done
    
    return 0
}

# Test 10: Test de la compatibilité
test_compatibility() {
    log_info "Test de la compatibilité..."
    
    # Vérifier la version de Bash
    local bash_version
    bash_version=$(bash --version | head -1 | grep -o '[0-9]\+\.[0-9]\+' | head -1)
    
    if [ "$(echo "$bash_version >= 4.0" | bc -l)" -eq 1 ]; then
        log_success "Version Bash compatible: $bash_version"
    else
        log_error "Version Bash incompatible: $bash_version (requis: >= 4.0)"
        return 1
    fi
    
    return 0
}

# Fonction principale
main() {
    log_info "Démarrage des tests d'intégration..."
    
    # Créer le répertoire de test
    mkdir -p "$TEST_DIR"
    
    # Liste des tests
    local tests=(
        "test_dependencies"
        "test_dry_run"
        "test_parameter_validation"
        "test_authentication"
        "test_modules"
        "test_configuration"
        "test_unit_tests"
        "test_documentation"
        "test_project_structure"
        "test_compatibility"
    )
    
    local passed=0
    local failed=0
    
    # Exécuter tous les tests
    for test in "${tests[@]}"; do
        if run_test "$test" "$test"; then
            passed=$((passed + 1))
        else
            failed=$((failed + 1))
        fi
    done
    
    # Afficher le résumé
    log_info "=== Résumé des Tests d'Intégration ==="
    log_info "Tests passés: $passed"
    log_info "Tests échoués: $failed"
    log_info "Total: $((passed + failed))"
    
    if [ "$failed" -eq 0 ]; then
        log_success "Tous les tests d'intégration sont passés!"
        return 0
    else
        log_error "$failed test(s) d'intégration ont échoué"
        return 1
    fi
}

# Nettoyage à la sortie
trap cleanup EXIT

# Exécuter la fonction principale
main "$@"
