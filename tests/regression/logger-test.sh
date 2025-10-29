#!/bin/bash
# Tests de régression : lib/logging/logger.sh
# Date : 2025-10-26

set -euo pipefail

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Sourcing module logger
source lib/logging/logger.sh

# Tests
PASSED=0
FAILED=0

test_function() {
    local test_name="$1"
    local command="$2"
    
    echo -n "Test: $test_name ... "
    if eval "$command" > /tmp/logger-test-output.log 2>&1; then
        echo -e "${GREEN}PASS${NC}"
        PASSED=$((PASSED + 1))
        return 0
    else
        echo -e "${RED}FAIL${NC}"
        cat /tmp/logger-test-output.log
        FAILED=$((FAILED + 1))
        return 1
    fi
}

echo "=== Tests de régression lib/logging/logger.sh ==="
echo

# TEST 1 : Fonctionnement normal
echo "--- TEST 1 : Fonctionnement Normal ---"
test_function "Initialisation normale" 'init_logger 0 false false true'
test_function "log_error()" 'log_error "Test error"'
test_function "log_warning()" 'log_warning "Test warning"'
test_function "log_info()" 'log_info "Test info"'
test_function "log_success()" 'log_success "Test success"'
test_function "logger_status()" 'logger_status'

echo

# TEST 2 : Validation paramètres init_logger
echo "--- TEST 2 : Validation Paramètres ---"
init_logger 0 false false true  # Réinitialiser pour tests
test_function "verbose_level invalide (abc)" '! init_logger "abc" false false true'
test_function "quiet_mode invalide (True)" '! init_logger 0 "True" false true'
test_function "dry_run_mode invalide (1)" '! init_logger 0 false "1" true'
test_function "timestamp invalide (yes)" '! init_logger 0 false false "yes"'

echo

# TEST 3 : Sorties stderr vs stdout
echo "--- TEST 3 : Sorties stderr vs stdout ---"
init_logger 0 false false true  # Réinitialiser
test_function "log_error_stderr()" 'log_error_stderr "Test stderr error"'
test_function "log_warning_stderr()" 'log_warning_stderr "Test stderr warning"'
test_function "log_info_stderr()" 'log_info_stderr "Test stderr info"'
test_function "log_success_stderr()" 'log_success_stderr "Test stderr success"'

echo

# TEST 4 : Integration modules dépendants
echo "--- TEST 4 : Integration ---"
test_function "Export fonctions" '[ "$(declare -f init_logger)" != "" ]'
test_function "Export log_error" '[ "$(declare -f log_error)" != "" ]'

# Résumé
echo
echo "=== Résumé ==="
echo "Passed: $PASSED"
echo "Failed: $FAILED"
if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ TOUS LES TESTS PASSÉS${NC}"
    exit 0
else
    echo -e "${RED}❌ ÉCHECS DÉTECTÉS${NC}"
    exit 1
fi
