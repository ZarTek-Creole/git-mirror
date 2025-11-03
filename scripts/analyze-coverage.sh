#!/bin/bash
# Script d'analyse complète de couverture de code
# Analyse toutes les fonctions et génère un rapport détaillé

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
readonly SCRIPT_DIR

# Couleurs
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Répertoires
readonly LIB_DIR="$SCRIPT_DIR/lib"
readonly TESTS_DIR="$SCRIPT_DIR/tests/spec/unit"
readonly COVERAGE_REPORT="$SCRIPT_DIR/coverage-analysis.json"

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

# Extraire toutes les fonctions d'un fichier
extract_functions() {
    local file="$1"
    # Chercher les fonctions avec ou sans espace avant {
    grep -E '^[a-zA-Z_][a-zA-Z0-9_]*\(\)' "$file" 2>/dev/null | \
        sed 's/()\s*{.*//' | \
        sed 's/()$//' | \
        sed 's/^[[:space:]]*//' | \
        sort -u || true
}

# Vérifier si une fonction est testée
is_function_tested() {
    local function_name="$1"
    local test_file="$2"
    
    if [ -f "$test_file" ]; then
        # Chercher dans "When call", "Describe", ou "call" (pour setup)
        if grep -qE "(When call |Describe '|call )$function_name\(" "$test_file" 2>/dev/null; then
            return 0
        fi
    fi
    return 1
}

# Analyser un module
analyze_module() {
    local module_file="$1"
    local module_name=$(basename "$module_file" .sh)
    local test_file="$TESTS_DIR/test_${module_name}_spec.sh"
    
    # Chercher des variantes de noms de fichiers de test
    if [ ! -f "$test_file" ]; then
        # Pour github_api -> test_api_spec.sh
        if [ "$module_name" = "github_api" ]; then
            test_file="$TESTS_DIR/test_api_spec.sh"
        # Pour parallel_optimized -> test_parallel_optimized_spec.sh
        elif [ "$module_name" = "parallel_optimized" ]; then
            test_file="$TESTS_DIR/test_parallel_optimized_spec.sh"
        else
            # Chercher tous les fichiers de test qui pourraient correspondre
            test_file=$(find "$TESTS_DIR" -name "*${module_name}*_spec.sh" -o -name "*test_*${module_name}*_spec.sh" 2>/dev/null | head -1)
        fi
    fi
    
    log_info "Analyse du module: $module_name"
    
    # Extraire toutes les fonctions
    local functions
    functions=$(extract_functions "$module_file")
    
    if [ -z "$functions" ]; then
        log_warning "Aucune fonction trouvée dans $module_file"
        return 0
    fi
    
    local total_functions=0
    local tested_functions=0
    local untested_functions=()
    
    while IFS= read -r func; do
        [ -z "$func" ] && continue
        total_functions=$((total_functions + 1))
        
        if is_function_tested "$func" "$test_file"; then
            tested_functions=$((tested_functions + 1))
        else
            untested_functions+=("$func")
        fi
    done <<< "$functions"
    
    # Calculer le pourcentage
    local coverage_percent=0
    if [ "$total_functions" -gt 0 ]; then
        coverage_percent=$((tested_functions * 100 / total_functions))
    fi
    
    # Afficher le résumé
    echo ""
    log_info "=== Module: $module_name ==="
    echo "  Total fonctions: $total_functions"
    echo "  Fonctions testées: $tested_functions"
    echo "  Fonctions non testées: $((total_functions - tested_functions))"
    echo "  Couverture: ${coverage_percent}%"
    
    if [ ${#untested_functions[@]} -gt 0 ]; then
        echo "  Fonctions à tester:"
        for func in "${untested_functions[@]}"; do
            echo "    - $func"
        done
    fi
    
    # Retourner les données au format JSON
    local json_data
    json_data=$(cat <<EOF
  {
    "module": "$module_name",
    "file": "$module_file",
    "test_file": "$test_file",
    "total_functions": $total_functions,
    "tested_functions": $tested_functions,
    "untested_functions": $((total_functions - tested_functions)),
    "coverage_percent": $coverage_percent,
    "untested_list": [$(printf '"%s",' "${untested_functions[@]}" | sed 's/,$//')]
  }
EOF
)
    echo "$json_data"
}

# Fonction principale
main() {
    log_info "=== Analyse de Couverture Complète ==="
    echo ""
    
    # Créer le rapport JSON
    echo "{" > "$COVERAGE_REPORT"
    echo '  "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'",' >> "$COVERAGE_REPORT"
    echo '  "modules": [' >> "$COVERAGE_REPORT"
    
    local first=true
    local total_modules=0
    local total_functions=0
    local total_tested=0
    
    # Analyser tous les modules
    while IFS= read -r module_file; do
        [ ! -f "$module_file" ] && continue
        
        if [ "$first" = true ]; then
            first=false
        else
            echo "," >> "$COVERAGE_REPORT"
        fi
        
        local module_data
        module_data=$(analyze_module "$module_file")
        echo "$module_data" >> "$COVERAGE_REPORT"
        
        # Extraire les statistiques
        local module_total
        module_total=$(echo "$module_data" | grep -o '"total_functions": [0-9]*' | grep -o '[0-9]*')
        local module_tested
        module_tested=$(echo "$module_data" | grep -o '"tested_functions": [0-9]*' | grep -o '[0-9]*')
        
        total_modules=$((total_modules + 1))
        total_functions=$((total_functions + module_total))
        total_tested=$((total_tested + module_tested))
    done < <(find "$LIB_DIR" -name "*.sh" -type f | sort)
    
    echo "" >> "$COVERAGE_REPORT"
    echo '  ],' >> "$COVERAGE_REPORT"
    
    # Calculer la couverture globale
    local global_coverage=0
    if [ "$total_functions" -gt 0 ]; then
        global_coverage=$((total_tested * 100 / total_functions))
    fi
    
    echo "  \"summary\": {" >> "$COVERAGE_REPORT"
    echo "    \"total_modules\": $total_modules," >> "$COVERAGE_REPORT"
    echo "    \"total_functions\": $total_functions," >> "$COVERAGE_REPORT"
    echo "    \"total_tested\": $total_tested," >> "$COVERAGE_REPORT"
    echo "    \"total_untested\": $((total_functions - total_tested))," >> "$COVERAGE_REPORT"
    echo "    \"global_coverage_percent\": $global_coverage" >> "$COVERAGE_REPORT"
    echo "  }" >> "$COVERAGE_REPORT"
    echo "}" >> "$COVERAGE_REPORT"
    
    # Afficher le résumé global
    echo ""
    log_success "=== Résumé Global ==="
    echo "  Modules analysés: $total_modules"
    echo "  Total fonctions: $total_functions"
    echo "  Fonctions testées: $total_tested"
    echo "  Fonctions non testées: $((total_functions - total_tested))"
    echo "  Couverture globale: ${global_coverage}%"
    echo ""
    
    if [ "$global_coverage" -lt 90 ]; then
        log_warning "Couverture en dessous de 90% (objectif minimum)"
        return 1
    else
        log_success "Couverture acceptable (>= 90%)"
        return 0
    fi
}

# Exécuter
main "$@"
