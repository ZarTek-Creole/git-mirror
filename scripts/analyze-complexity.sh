#!/bin/bash
# Script d'analyse de complexité cyclomatique et amélioration du code
# Objectif: Réduire la complexité, améliorer les pratiques, vérifier les design patterns

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
    
    # Compter les structures de contrôle
    local if_count=$(grep -c "^[^#]*\bif\b" "$file" 2>/dev/null || echo 0)
    local case_count=$(grep -c "^[^#]*\bcase\b" "$file" 2>/dev/null || echo 0)
    local while_count=$(grep -c "^[^#]*\bwhile\b" "$file" 2>/dev/null || echo 0)
    local for_count=$(grep -c "^[^#]*\bfor\b" "$file" 2>/dev/null || echo 0)
    local until_count=$(grep -c "^[^#]*\buntil\b" "$file" 2>/dev/null || echo 0)
    local and_count=$(grep -c "^[^#]*&&" "$file" 2>/dev/null || echo 0)
    local or_count=$(grep -c "^[^#]*||" "$file" 2>/dev/null || echo 0)
    
    complexity=$((complexity + if_count + case_count + while_count + for_count + until_count + and_count + or_count))
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
        function_count=$(grep -c "^[a-zA-Z_][a-zA-Z0-9_]*()" "$module_file" 2>/dev/null || echo 0)
        line_count=$(wc -l < "$module_file" 2>/dev/null || echo 0)
        
        module_complexity["$module_name"]=$complexity
        module_functions["$module_name"]=$function_count
        module_lines["$module_name"]=$line_count
        
        printf "  %-30s Complexité: %3d  Fonctions: %2d  Lignes: %4d\n" \
            "$module_name" "$complexity" "$function_count" "$line_count"
    fi
done

echo ""
echo "=== Vérification des Meilleures Pratiques ==="
echo ""

# Vérifier l'utilisation de set -euo pipefail
echo "1. Configuration de sécurité (set -euo pipefail):"
missing_security=0
for module_file in "$LIB_DIR"/*/*.sh; do
    if [ -f "$module_file" ]; then
        if ! grep -q "set -euo pipefail" "$module_file" 2>/dev/null; then
            echo "  ⚠️  $(basename "$module_file"): Manque 'set -euo pipefail'"
            missing_security=$((missing_security + 1))
        fi
    fi
done
if [ $missing_security -eq 0 ]; then
    echo "  ✅ Tous les modules ont 'set -euo pipefail'"
fi

# Vérifier les variables readonly
echo ""
echo "2. Utilisation de variables readonly:"
readonly_count=0
for module_file in "$LIB_DIR"/*/*.sh; do
    if [ -f "$module_file" ]; then
        count=$(grep -c "readonly" "$module_file" 2>/dev/null || echo 0)
        readonly_count=$((readonly_count + count))
    fi
done
echo "  Total variables readonly: $readonly_count"

# Vérifier la documentation des fonctions
echo ""
echo "3. Documentation des fonctions:"
undocumented=0
for module_file in "$LIB_DIR"/*/*.sh; do
    if [ -f "$module_file" ]; then
        functions=$(grep "^[a-zA-Z_][a-zA-Z0-9_]*()" "$module_file" 2>/dev/null | head -5)
        while IFS= read -r func; do
            func_name=$(echo "$func" | sed 's/()//')
            # Vérifier si la fonction a un commentaire avant elle
            func_line=$(grep -n "^$func_name()" "$module_file" | cut -d: -f1)
            if [ -n "$func_line" ] && [ "$func_line" -gt 1 ]; then
                prev_line=$((func_line - 1))
                prev_content=$(sed -n "${prev_line}p" "$module_file")
                if ! echo "$prev_content" | grep -q "^#"; then
                    undocumented=$((undocumented + 1))
                fi
            fi
        done <<< "$functions"
    fi
done
echo "  Fonctions potentiellement non documentées: $undocumented"

# Vérifier l'utilisation de log_* au lieu de echo
echo ""
echo "4. Utilisation du système de logging:"
echo_usage=0
log_usage=0
for module_file in "$LIB_DIR"/*/*.sh; do
    if [ -f "$module_file" ]; then
        echo_count=$(grep -c "echo " "$module_file" 2>/dev/null || echo 0)
        log_count=$(grep -c "log_" "$module_file" 2>/dev/null || echo 0)
        echo_usage=$((echo_usage + echo_count))
        log_usage=$((log_usage + log_count))
    fi
done
echo "  Utilisation de 'echo': $echo_usage"
echo "  Utilisation de 'log_*': $log_usage"

# Générer rapport JSON
cat > "$PROJECT_ROOT/complexity-analysis.json" <<EOF
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "modules": [
EOF

first=true
for module_name in "${!module_complexity[@]}"; do
    if [ "$first" = true ]; then
        first=false
    else
        echo "," >> "$PROJECT_ROOT/complexity-analysis.json"
    fi
    cat >> "$PROJECT_ROOT/complexity-analysis.json" <<EOF
    {
      "module": "$module_name",
      "complexity": ${module_complexity[$module_name]},
      "functions": ${module_functions[$module_name]},
      "lines": ${module_lines[$module_name]},
      "avg_complexity_per_function": $(echo "scale=2; ${module_complexity[$module_name]} / ${module_functions[$module_name]}" | bc -l 2>/dev/null || echo "0")
    }
EOF
done

cat >> "$PROJECT_ROOT/complexity-analysis.json" <<EOF
  ],
  "summary": {
    "total_modules": ${#module_complexity[@]},
    "avg_complexity": 0,
    "max_complexity": $(IFS=$'\n'; echo "${module_complexity[*]}" | sort -n | tail -1),
    "readonly_variables": $readonly_count,
    "echo_usage": $echo_usage,
    "log_usage": $log_usage
  }
}
EOF

echo ""
echo "✅ Rapport généré: complexity-analysis.json"
echo ""
echo "=== Recommandations ==="
echo ""
echo "1. Complexité élevée (>20): Considérer la refactorisation"
echo "2. Documentation: Ajouter des commentaires pour toutes les fonctions"
echo "3. Logging: Préférer log_* à echo pour la sortie"
echo "4. Sécurité: Tous les modules doivent avoir 'set -euo pipefail'"
echo ""
