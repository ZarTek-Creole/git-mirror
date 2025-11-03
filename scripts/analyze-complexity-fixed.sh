#!/bin/bash
# Script d'analyse de complexité cyclomatique et amélioration du code

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LIB_DIR="$PROJECT_ROOT/lib"

echo "=== Analyse de Complexité et Qualité du Code ==="
echo ""

# Fonction pour calculer la complexité cyclomatique approximative
calculate_complexity() {
    local file="$1"
    local complexity=1  # Base complexity
    
    if [ ! -f "$file" ]; then
        echo "1"
        return
    fi
    
    # Compter les structures de contrôle
    local count=0
    
    # Utiliser grep avec wc -l pour un comptage fiable
    count=$((count + $(grep -E '^[^#]*\bif\b' "$file" 2>/dev/null | wc -l | tr -d ' ' || echo 0)))
    count=$((count + $(grep -E '^[^#]*\bcase\b' "$file" 2>/dev/null | wc -l | tr -d ' ' || echo 0)))
    count=$((count + $(grep -E '^[^#]*\bwhile\b' "$file" 2>/dev/null | wc -l | tr -d ' ' || echo 0)))
    count=$((count + $(grep -E '^[^#]*\bfor\b' "$file" 2>/dev/null | wc -l | tr -d ' ' || echo 0)))
    count=$((count + $(grep -E '^[^#]*\buntil\b' "$file" 2>/dev/null | wc -l | tr -d ' ' || echo 0)))
    count=$((count + $(grep -E '^[^#]*&&' "$file" 2>/dev/null | wc -l | tr -d ' ' || echo 0)))
    count=$((count + $(grep -E '^[^#]*\|\|' "$file" 2>/dev/null | wc -l | tr -d ' ' || echo 0)))
    
    complexity=$((complexity + count))
    echo "$complexity"
}

# Analyser chaque module
echo "Analyse de la complexité par module:"
echo "-----------------------------------"

declare -A module_complexity
declare -A module_functions
declare -A module_lines

for module_file in "$LIB_DIR"/*/*.sh; do
    if [ -f "$module_file" ]; then
        module_name=$(basename "$module_file" .sh)
        complexity=$(calculate_complexity "$module_file")
        function_count=$(grep -c "^[a-zA-Z_][a-zA-Z0-9_]*()" "$module_file" 2>/dev/null || echo "0")
        line_count=$(wc -l < "$module_file" 2>/dev/null || echo "0")
        
        module_complexity["$module_name"]=$complexity
        module_functions["$module_name"]=$function_count
        module_lines["$module_name"]=$line_count
        
        printf "  %-30s Complexité: %3d  Fonctions: %2d  Lignes: %4d\n" \
            "$module_name" "$complexity" "$function_count" "$line_count"
    fi
done

echo ""
echo "=== Modules avec Complexité Élevée (>20) ==="
high_complexity=0
for module_name in "${!module_complexity[@]}"; do
    if [ "${module_complexity[$module_name]}" -gt 20 ]; then
        echo "  ⚠️  $module_name: ${module_complexity[$module_name]}"
        high_complexity=$((high_complexity + 1))
    fi
done

if [ $high_complexity -eq 0 ]; then
    echo "  ✅ Aucun module avec complexité élevée"
fi

echo ""
echo "✅ Analyse terminée"
