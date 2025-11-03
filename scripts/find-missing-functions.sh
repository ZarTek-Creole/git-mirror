#!/bin/bash
# Script pour trouver précisément les fonctions non testées

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LIB_DIR="$PROJECT_ROOT/lib"
TESTS_DIR="$PROJECT_ROOT/tests/spec/unit"

echo "=== Recherche des Fonctions Non Testées ==="
echo ""

# Fonction pour extraire les fonctions d'un fichier
extract_functions() {
    local file="$1"
    grep "^[a-zA-Z_][a-zA-Z0-9_]*()" "$file" 2>/dev/null | sed 's/()//' | sort
}

# Fonction pour extraire les fonctions testées d'un fichier de test
extract_tested_functions() {
    local test_file="$1"
    # Chercher les patterns "When call function_name" ou "Describe 'function_name()"
    grep -E "(When call |Describe ')[a-zA-Z_][a-zA-Z0-9_]*\(" "$test_file" 2>/dev/null | \
        sed -E 's/.*(When call |Describe '"'"')([a-zA-Z_][a-zA-Z0-9_]*)\(.*/\2/' | sort -u
}

# Parcourir tous les modules
for module_file in "$LIB_DIR"/*/*.sh; do
    if [ ! -f "$module_file" ]; then
        continue
    fi
    
    module_name=$(basename "$module_file" .sh)
    test_file="$TESTS_DIR/test_${module_name}_spec.sh"
    
    # Si pas de fichier de test correspondant, chercher avec des variantes
    if [ ! -f "$test_file" ]; then
        # Chercher des variantes
        test_file=$(find "$TESTS_DIR" -name "*${module_name}*_spec.sh" -o -name "*test_*${module_name}*_spec.sh" 2>/dev/null | head -1)
    fi
    
    # Extraire les fonctions du module
    module_functions=$(extract_functions "$module_file")
    
    if [ -z "$module_functions" ]; then
        continue
    fi
    
    # Extraire les fonctions testées
    tested_functions=""
    if [ -f "$test_file" ]; then
        tested_functions=$(extract_tested_functions "$test_file")
    fi
    
    # Trouver les fonctions non testées
    untested_functions=$(comm -23 <(echo "$module_functions") <(echo "$tested_functions"))
    
    if [ -n "$untested_functions" ]; then
        echo "Module: $module_name"
        echo "  Fichier: $module_file"
        echo "  Test: ${test_file:-NON TROUVÉ}"
        echo "  Fonctions non testées:"
        echo "$untested_functions" | sed 's/^/    - /'
        echo ""
    fi
done

echo "=== Fin de la recherche ==="
