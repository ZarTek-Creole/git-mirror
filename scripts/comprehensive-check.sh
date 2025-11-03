#!/bin/bash
# Script de vérification complète de tous les aspects du projet

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LIB_DIR="$PROJECT_ROOT/lib"
TESTS_DIR="$PROJECT_ROOT/tests/spec/unit"

# Couleurs
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

echo "=== VÉRIFICATION COMPLÈTE DU PROJET ==="
echo ""

# 1. Vérifier la couverture par module (>90%)
echo "1. VÉRIFICATION DE LA COUVERTURE (>90%)"
echo "----------------------------------------"

total_functions=0
total_tested=0
modules_below_90=0

for module_file in "$LIB_DIR"/*/*.sh; do
    [ ! -f "$module_file" ] && continue
    
    module_name=$(basename "$module_file" .sh)
    test_file=$(find "$TESTS_DIR" -name "*${module_name}*_spec.sh" -o -name "*test_*${module_name}*_spec.sh" 2>/dev/null | head -1)
    
    # Cas spéciaux
    [ "$module_name" = "github_api" ] && test_file="$TESTS_DIR/test_api_spec.sh"
    [ "$module_name" = "parallel_optimized" ] && test_file="$TESTS_DIR/test_parallel_optimized_spec.sh"
    
    functions=$(grep -E '^[a-zA-Z_][a-zA-Z0-9_]*\(\)' "$module_file" 2>/dev/null | wc -l)
    tested=0
    
    if [ -f "$test_file" ]; then
        tested=$(grep -E "(When call |Describe '|call )" "$test_file" 2>/dev/null | grep -c "(" || echo "0")
    fi
    
    if [ "$functions" -gt 0 ]; then
        coverage=$((tested * 100 / functions))
        total_functions=$((total_functions + functions))
        total_tested=$((total_tested + tested))
        
        if [ "$coverage" -lt 90 ]; then
            echo -e "  ${RED}⚠️  $module_name: ${coverage}% (${tested}/${functions})${NC}"
            modules_below_90=$((modules_below_90 + 1))
        else
            echo -e "  ${GREEN}✅ $module_name: ${coverage}% (${tested}/${functions})${NC}"
        fi
    fi
done

global_coverage=0
if [ "$total_functions" -gt 0 ]; then
    global_coverage=$((total_tested * 100 / total_functions))
fi

echo ""
echo "Couverture globale: ${global_coverage}% (${total_tested}/${total_functions})"
if [ "$modules_below_90" -gt 0 ]; then
    echo -e "${RED}⚠️  $modules_below_90 modules en dessous de 90%${NC}"
else
    echo -e "${GREEN}✅ Tous les modules >= 90%${NC}"
fi

echo ""
echo "2. VÉRIFICATION DE LA COMPLEXITÉ"
echo "----------------------------------"

high_complexity=0
for module_file in "$LIB_DIR"/*/*.sh; do
    [ ! -f "$module_file" ] && continue
    
    module_name=$(basename "$module_file" .sh)
    
    # Compter les structures de contrôle
    complexity=$(grep -E '^\s*(if|case|while|for|until)\s+|&&|\|\|' "$module_file" 2>/dev/null | wc -l)
    functions=$(grep -E '^[a-zA-Z_][a-zA-Z0-9_]*\(\)' "$module_file" 2>/dev/null | wc -l)
    
    if [ "$functions" -gt 0 ]; then
        avg_complexity=$((complexity / functions))
        if [ "$avg_complexity" -gt 5 ]; then
            echo -e "  ${YELLOW}⚠️  $module_name: Complexité moyenne ${avg_complexity}${NC}"
            high_complexity=$((high_complexity + 1))
        else
            echo -e "  ${GREEN}✅ $module_name: Complexité moyenne ${avg_complexity}${NC}"
        fi
    fi
done

echo ""
echo "3. VÉRIFICATION DES MEILLEURES PRATIQUES"
echo "------------------------------------------"

# Vérifier readonly
readonly_count=$(grep -r "readonly\|declare -r\|local -r" "$LIB_DIR" 2>/dev/null | wc -l)
echo "  Variables readonly: $readonly_count"

# Vérifier set -euo pipefail
modules_with_security=0
for module_file in "$LIB_DIR"/*/*.sh; do
    if grep -q "set -euo pipefail" "$module_file" 2>/dev/null; then
        modules_with_security=$((modules_with_security + 1))
    fi
done
echo "  Modules avec set -euo pipefail: ${modules_with_security}/16"

# Vérifier l'utilisation de log_* vs echo
echo_count=$(grep -r "echo " "$LIB_DIR" 2>/dev/null | grep -v "echo \"" | grep -v "echo '" | grep -v "echo \$" | wc -l)
log_count=$(grep -r "log_" "$LIB_DIR" 2>/dev/null | wc -l)
echo "  Utilisation de log_*: $log_count"
echo "  Utilisation de echo (hors retour): $echo_count"

echo ""
echo "4. VÉRIFICATION DES DESIGN PATTERNS"
echo "-------------------------------------"

# Singleton (config)
if grep -q "MODULE_LOADED\|singleton" "$LIB_DIR"/*/*.sh 2>/dev/null; then
    echo -e "  ${GREEN}✅ Pattern Singleton détecté${NC}"
else
    echo -e "  ${YELLOW}⚠️  Pattern Singleton non utilisé${NC}"
fi

# Factory (auth)
if grep -q "auth_detect\|factory" "$LIB_DIR"/auth/auth.sh 2>/dev/null; then
    echo -e "  ${GREEN}✅ Pattern Factory détecté${NC}"
else
    echo -e "  ${YELLOW}⚠️  Pattern Factory non utilisé${NC}"
fi

# Strategy (parallel)
if grep -q "parallel_execute\|strategy" "$LIB_DIR"/parallel/*.sh 2>/dev/null; then
    echo -e "  ${GREEN}✅ Pattern Strategy détecté${NC}"
else
    echo -e "  ${YELLOW}⚠️  Pattern Strategy non utilisé${NC}"
fi

# Observer (hooks)
if grep -q "hooks_execute\|observer" "$LIB_DIR"/hooks/hooks.sh 2>/dev/null; then
    echo -e "  ${GREEN}✅ Pattern Observer détecté${NC}"
else
    echo -e "  ${YELLOW}⚠️  Pattern Observer non utilisé${NC}"
fi

echo ""
echo "5. VÉRIFICATION DES VERSIONS ET FONCTIONS MODERNES"
echo "----------------------------------------------------"

# Vérifier l'utilisation de features modernes Bash
if grep -qr "declare -A\|mapfile\|readarray" "$LIB_DIR" 2>/dev/null; then
    echo -e "  ${GREEN}✅ Tableaux associatifs utilisés${NC}"
else
    echo -e "  ${YELLOW}⚠️  Tableaux associatifs non utilisés${NC}"
fi

# Vérifier l'utilisation de process substitution
if grep -qr "<(" "$LIB_DIR" 2>/dev/null; then
    echo -e "  ${GREEN}✅ Process substitution utilisée${NC}"
else
    echo -e "  ${YELLOW}⚠️  Process substitution non utilisée${NC}"
fi

# Vérifier l'utilisation de jq moderne
if grep -qr "jq.*--argjson\|jq.*fromdateiso8601" "$LIB_DIR" 2>/dev/null; then
    echo -e "  ${GREEN}✅ Fonctions jq modernes utilisées${NC}"
else
    echo -e "  ${YELLOW}⚠️  Fonctions jq modernes non utilisées${NC}"
fi

echo ""
echo "=== RÉSUMÉ ==="
echo "Couverture: ${global_coverage}%"
echo "Modules complexes: $high_complexity"
echo ""

if [ "$modules_below_90" -eq 0 ] && [ "$global_coverage" -ge 90 ]; then
    echo -e "${GREEN}✅ Tous les critères sont respectés!${NC}"
    exit 0
else
    echo -e "${RED}⚠️  Certains critères ne sont pas respectés${NC}"
    exit 1
fi
