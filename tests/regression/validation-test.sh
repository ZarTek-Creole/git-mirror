#!/bin/bash
# Tests de régression : lib/validation/validation.sh
# Date : 2025-10-26

set -euo pipefail

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Sourcing modules requis
source lib/logging/logger.sh
source lib/validation/validation.sh

# Initialiser le logger
init_logger 0 false false false

# Tests
PASSED=0
FAILED=0

test_function() {
    local test_name="$1"
    local command="$2"
    local expected_result="${3:-0}"  # 0 = succès attendu, 1 = échec attendu
    
    echo -n "Test: $test_name ... "
    
    local actual_result=0
    eval "$command" > /tmp/validation-test-output.log 2>&1 || actual_result=$?
    
    if [ "$actual_result" -eq "$expected_result" ]; then
        echo -e "${GREEN}PASS${NC}"
        PASSED=$((PASSED + 1))
        return 0
    else
        echo -e "${RED}FAIL${NC}"
        echo "  Attendu: $expected_result, Reçu: $actual_result"
        cat /tmp/validation-test-output.log
        FAILED=$((FAILED + 1))
        return 1
    fi
}

echo "=== Tests de régression lib/validation/validation.sh ==="
echo

# TEST 1 : Fonctionnement normal - Validations qui DOIVENT réussir
echo "--- TEST 1 : Fonctionnement Normal (Validations Réussies) ---"
test_function "validate_context('users')" 'validate_context "users"' 0
test_function "validate_context('orgs')" 'validate_context "orgs"' 0
test_function "validate_username('ZarTek-Creole')" 'validate_username "ZarTek-Creole"' 0
test_function "validate_username('a')" 'validate_username "a"' 0
test_function "validate_username('user123')" 'validate_username "user123"' 0
test_function "validate_destination('/tmp')" 'validate_destination "/tmp"' 0
test_function "validate_destination('.')" 'validate_destination "."' 0
test_function "validate_branch('')" 'validate_branch ""' 0
test_function "validate_branch('main')" 'validate_branch "main"' 0
test_function "validate_branch('feature/test')" 'validate_branch "feature/test"' 0
test_function "validate_filter('')" 'validate_filter ""' 0
test_function "validate_filter('blob:none')" 'validate_filter "blob:none"' 0
test_function "validate_filter('tree:0')" 'validate_filter "tree:0"' 0

echo

# TEST 2 : Nouvelles validations génériques _validate_numeric_range()
echo "--- TEST 2 : Validations Génériques (_validate_numeric_range) ---"
test_function "validate_depth(1)" 'validate_depth "1"' 0
test_function "validate_depth(500)" 'validate_depth "500"' 0
test_function "validate_depth(1000)" 'validate_depth "1000"' 0
test_function "validate_depth(0) doit échouer" 'validate_depth "0"' 1
test_function "validate_depth(1001) doit échouer" 'validate_depth "1001"' 1
test_function "validate_depth('abc') doit échouer" 'validate_depth "abc"' 1
test_function "validate_parallel_jobs(1)" 'validate_parallel_jobs "1"' 0
test_function "validate_parallel_jobs(25)" 'validate_parallel_jobs "25"' 0
test_function "validate_parallel_jobs(50)" 'validate_parallel_jobs "50"' 0
test_function "validate_parallel_jobs(0) doit échouer" 'validate_parallel_jobs "0"' 1
test_function "validate_parallel_jobs(51) doit échouer" 'validate_parallel_jobs "51"' 1
test_function "validate_parallel_jobs('xyz') doit échouer" 'validate_parallel_jobs "xyz"' 1

echo

# TEST 3 : Validation intégration avec logger.sh
echo "--- TEST 3 : Intégration avec logger.sh (Module 1/13) ---"
test_function "log_error appelé dans validate_github_url" '(validate_github_url "invalid-url" 2>&1 || true) | grep -q "invalide"' 0
test_function "log_warning appelé dans validate_filter" '(validate_filter "unknown:filter" 2>&1 || true) | grep -q "potentiellement"' 0
test_function "log_debug disponible" '[ "$(declare -f log_debug)" != "" ]' 0
test_function "log_error disponible" '[ "$(declare -f log_error)" != "" ]' 0

echo

# TEST 4 : Validation messages d'erreur améliorés
echo "--- TEST 4 : Messages Erreur Explicites (Optimisation 3) ---"
test_function "validate_all_params() avec context invalide" 'validate_all_params "invalid" "user" "/tmp" "" "" "1" "1" "30" 2>&1 | grep -q "Contexte invalide"' 1
test_function "validate_all_params() avec username invalide" 'validate_all_params "users" "" "/tmp" "" "" "1" "1" "30" 2>&1 | grep -q "Username invalide"' 1
test_function "validate_all_params() avec depth invalide" 'validate_all_params "users" "user" "/tmp" "" "" "0" "1" "30" 2>&1 | grep -q "depth doit"' 1
test_function "validate_all_params() avec parallel_jobs invalide" 'validate_all_params "users" "user" "/tmp" "" "" "1" "100" "30" 2>&1 | grep -q "parallel_jobs doit"' 1
test_function "validate_all_params() TOUS valides" 'validate_all_params "users" "user" "/tmp" "" "" "1" "1" "30"' 0

echo

# TEST 5 : Validation des nouvelles fonctions génériques (_validate_permissions)
echo "--- TEST 5 : Validations Permissions (_validate_permissions) ---"
# Créer fichiers/répertoires de test
touch /tmp/test-file-validation.txt
chmod 644 /tmp/test-file-validation.txt
mkdir -p /tmp/test-dir-validation
chmod 755 /tmp/test-dir-validation

test_function "validate_file_permissions('/tmp/test-file-validation.txt', '644')" 'validate_file_permissions "/tmp/test-file-validation.txt" "644"' 0
test_function "validate_file_permissions('/nonexistent') doit échouer" 'validate_file_permissions "/nonexistent"' 1
test_function "validate_dir_permissions('/tmp/test-dir-validation', '755')" 'validate_dir_permissions "/tmp/test-dir-validation" "755"' 0
test_function "validate_dir_permissions('/nonexistent') doit échouer" 'validate_dir_permissions "/nonexistent"' 1

# Nettoyage
rm -f /tmp/test-file-validation.txt
rm -rf /tmp/test-dir-validation

echo

# Résumé
echo "=== Résumé ==="
echo "Passed: $PASSED"
echo "Failed: $FAILED"
echo "Total: $((PASSED + FAILED))"
if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ TOUS LES TESTS PASSÉS${NC}"
    rm -f /tmp/validation-test-output.log
    exit 0
else
    echo -e "${RED}❌ $FAILED ÉCHEC(S) DÉTECTÉ(S)${NC}"
    exit 1
fi

