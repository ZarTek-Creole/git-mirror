#!/bin/bash
# Script pour générer des stubs de tests pour toutes les fonctions non testées

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
readonly SCRIPT_DIR
readonly LIB_DIR="$SCRIPT_DIR/lib"
readonly TESTS_DIR="$SCRIPT_DIR/tests/spec/unit"
readonly COVERAGE_FILE="$SCRIPT_DIR/coverage-analysis.json"

# Extraire les fonctions non testées d'un module
get_untested_functions() {
    local module_name="$1"
    jq -r ".modules[] | select(.module == \"$module_name\") | .untested_list[]" "$COVERAGE_FILE" 2>/dev/null || true
}

# Générer un stub de test pour une fonction
generate_test_stub() {
    local function_name="$1"
    local module_name="$2"
    
    cat <<EOF
  Describe '$function_name() - Function Description'
    It 'should execute successfully'
      When call $function_name
      The status should be success
    End
    
    It 'should handle invalid input'
      When call $function_name ""
      The status should be failure
    End
    
    It 'should handle edge cases'
      When call $function_name "edge_case"
      The status should be success
    End
  End

EOF
}

# Générer un fichier de test complet
generate_test_file() {
    local module_name="$1"
    local test_file="$TESTS_DIR/test_${module_name}_spec.sh"
    
    # Vérifier si le fichier existe déjà
    if [ -f "$test_file" ]; then
        echo "Fichier existe déjà: $test_file"
        return 0
    fi
    
    local untested_functions
    untested_functions=$(get_untested_functions "$module_name")
    
    if [ -z "$untested_functions" ]; then
        echo "Aucune fonction non testée pour $module_name"
        return 0
    fi
    
    # Créer le fichier de test
    cat > "$test_file" <<EOF
#!/usr/bin/env shellspec
# Tests ShellSpec pour module ${module_name}
# Généré automatiquement - À compléter avec des tests spécifiques

Describe '${module_name^} Module - Test Suite'

  setup_${module_name}() {
    export GIT_MIRROR_TEST_MODE=true
    export VERBOSE_LEVEL=0
    export QUIET_MODE=false
    export DRY_RUN_MODE=false
    
    # Charger les dépendances nécessaires
    source lib/logging/logger.sh
    
    # Charger le module à tester
    source lib/${module_name}/${module_name}.sh
    
    # Setup spécifique au module
    ${module_name}_setup 2>/dev/null || true
  }

  teardown_${module_name}() {
    # Cleanup spécifique au module
    true
  }

  Before setup_${module_name}
  After teardown_${module_name}

EOF

    # Ajouter les stubs de tests pour chaque fonction
    while IFS= read -r func; do
        [ -z "$func" ] && continue
        generate_test_stub "$func" "$module_name" >> "$test_file"
    done <<< "$untested_functions"
    
    echo "End" >> "$test_file"
    
    chmod +x "$test_file"
    echo "Fichier de test créé: $test_file"
}

# Fonction principale
main() {
    echo "=== Génération de Stubs de Tests ==="
    echo ""
    
    # Lire la liste des modules depuis le fichier de couverture
    if [ ! -f "$COVERAGE_FILE" ]; then
        echo "Erreur: Fichier de couverture non trouvé: $COVERAGE_FILE"
        echo "Exécutez d'abord: bash scripts/analyze-coverage.sh"
        return 1
    fi
    
    # Générer les tests pour chaque module avec des fonctions non testées
    jq -r '.modules[] | select(.untested_functions > 0) | .module' "$COVERAGE_FILE" | \
    while read -r module; do
        echo "Génération des tests pour: $module"
        generate_test_file "$module"
    done
    
    echo ""
    echo "=== Génération terminée ==="
    echo "Note: Les stubs générés doivent être complétés avec des tests spécifiques"
}

main "$@"
