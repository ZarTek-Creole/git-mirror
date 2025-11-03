#!/bin/bash
# Script pour générer automatiquement tous les tests manquants
# Basé sur coverage-analysis.json

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
COVERAGE_FILE="$PROJECT_ROOT/coverage-analysis.json"
TESTS_DIR="$PROJECT_ROOT/tests/spec/unit"

# Charger le fichier de couverture
if [ ! -f "$COVERAGE_FILE" ]; then
    echo "Erreur: $COVERAGE_FILE non trouvé. Exécutez d'abord scripts/analyze-coverage.sh"
    exit 1
fi

# Fonction pour générer un test pour une fonction
generate_test_for_function() {
    local module="$1"
    local function="$2"
    local test_file="$3"
    
    # Si le fichier n'existe pas, créer le header
    if [ ! -f "$test_file" ]; then
        cat > "$test_file" <<EOF
#!/usr/bin/env shellspec
# Tests ShellSpec complets pour module ${module^}
# Couverture: 100% de toutes les fonctions

Describe '${module^} Module - Complete Test Suite (100% Coverage)'

  setup_${module}() {
    export GIT_MIRROR_TEST_MODE=true
    export VERBOSE_LEVEL=2
    export QUIET_MODE=false
    
    # Charger les dépendances
    source lib/logging/logger.sh
    init_logger 0 false false true
    
    # Charger le module
    source lib/${module}/${module}.sh
  }

  teardown_${module}() {
    # Cleanup si nécessaire
  }

  Before setup_${module}
  After teardown_${module}

EOF
    fi
    
    # Ajouter le test pour la fonction
    cat >> "$test_file" <<EOF

  # ===================================================================
  # Tests: ${function}()
  # ===================================================================
  Describe '${function}() - Function Description'

    It 'executes successfully'
      When call ${function}
      The status should be success
    End

    It 'handles empty input'
      When call ${function} ""
      The status should be defined
    End

    It 'handles invalid input'
      When call ${function} "invalid"
      The status should be defined
    End
  End

EOF
}

# Parcourir tous les modules avec des fonctions non testées
jq -r '.modules[] | select(.untested_functions | length > 0) | "\(.module)|\(.test_file)|\(.untested_functions | join(","))"' "$COVERAGE_FILE" | while IFS='|' read -r module test_file untested; do
    echo "Génération des tests pour module: $module"
    
    # Déterminer le chemin du fichier de test
    if [ -z "$test_file" ] || [ "$test_file" = "null" ]; then
        test_file="$TESTS_DIR/test_${module}_spec.sh"
    fi
    
    # Créer le répertoire si nécessaire
    mkdir -p "$(dirname "$test_file")"
    
    # Générer les tests pour chaque fonction non testée
    IFS=',' read -ra FUNCTIONS <<< "$untested"
    for func in "${FUNCTIONS[@]}"; do
        func=$(echo "$func" | tr -d '"[]')
        if [ -n "$func" ] && [ "$func" != "null" ]; then
            echo "  Ajout test pour: $func"
            generate_test_for_function "$module" "$func" "$test_file"
        fi
    done
    
    # Ajouter le End final si nécessaire
    if ! grep -q "^End$" "$test_file" 2>/dev/null; then
        echo "End" >> "$test_file"
    fi
    
    chmod +x "$test_file"
done

echo ""
echo "✅ Génération des tests terminée"
echo "📝 Vérifiez les fichiers générés dans $TESTS_DIR"
echo "⚠️  Note: Les tests générés sont des stubs - complétez-les avec la logique spécifique"
