#!/bin/bash
# Script pour améliorer automatiquement la qualité du code
# - Remplacer echo par log_*
# - Ajouter variables readonly
# - Améliorer la documentation
# - Vérifier les meilleures pratiques

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LIB_DIR="$PROJECT_ROOT/lib"

echo "=== Amélioration de la Qualité du Code ==="
echo ""

# Compter les améliorations
IMPROVEMENTS=0

# Fonction pour remplacer echo par log_* dans un fichier
improve_logging() {
    local file="$1"
    local changed=false
    
    # Remplacer echo par log_info (général)
    if grep -q "^[^#]*echo " "$file" 2>/dev/null; then
        # Attention: ne pas remplacer les echo dans les fonctions log_* elles-mêmes
        if [[ ! "$file" =~ logger\.sh$ ]]; then
            echo "  ⚠️  $file contient des 'echo' - considérer utiliser log_*"
            IMPROVEMENTS=$((IMPROVEMENTS + 1))
        fi
    fi
}

# Fonction pour vérifier/add readonly
improve_readonly() {
    local file="$1"
    local const_count=0
    
    # Compter les variables qui devraient être readonly
    if grep -q "^[^#]*\(DEFAULT_\|MAX_\|MIN_\|TIMEOUT_\|RETRY_\)" "$file" 2>/dev/null; then
        echo "  💡 $file contient des constantes qui pourraient être readonly"
        IMPROVEMENTS=$((IMPROVEMENTS + 1))
    fi
}

# Fonction pour améliorer la documentation
improve_documentation() {
    local file="$1"
    local func_count=0
    local doc_count=0
    
    # Compter les fonctions sans documentation
    while IFS= read -r line; do
        if [[ "$line" =~ ^[a-zA-Z_][a-zA-Z0-9_]*\(\) ]]; then
            func_count=$((func_count + 1))
            # Vérifier si la ligne précédente est un commentaire
            local line_num=$(grep -n "^$line" "$file" | cut -d: -f1)
            if [ -n "$line_num" ] && [ "$line_num" -gt 1 ]; then
                local prev_line=$((line_num - 1))
                local prev_content=$(sed -n "${prev_line}p" "$file")
                if echo "$prev_content" | grep -q "^#"; then
                    doc_count=$((doc_count + 1))
                fi
            fi
        fi
    done < <(grep "^[a-zA-Z_][a-zA-Z0-9_]*()" "$file" 2>/dev/null | head -10)
    
    if [ $func_count -gt 0 ] && [ $doc_count -lt $func_count ]; then
        echo "  📝 $file: $((func_count - doc_count)) fonctions sans documentation"
        IMPROVEMENTS=$((IMPROVEMENTS + 1))
    fi
}

# Analyser chaque module
echo "Analyse des améliorations possibles:"
echo "-----------------------------------"

for module_file in "$LIB_DIR"/*/*.sh; do
    if [ -f "$module_file" ]; then
        module_name=$(basename "$module_file" .sh)
        echo ""
        echo "Module: $module_name"
        improve_logging "$module_file"
        improve_readonly "$module_file"
        improve_documentation "$module_file"
    fi
done

echo ""
echo "=== Vérification des Versions ==="
echo ""

# Vérifier la version Bash
if [ -n "${BASH_VERSION:-}" ]; then
    echo "Bash version: $BASH_VERSION"
    bash_major=$(echo "$BASH_VERSION" | cut -d. -f1)
    bash_minor=$(echo "$BASH_VERSION" | cut -d. -f2)
    if [ "$bash_major" -lt 4 ] || ([ "$bash_major" -eq 4 ] && [ "$bash_minor" -lt 4 ]); then
        echo "  ⚠️  Version Bash < 4.4 - certaines fonctionnalités modernes ne sont pas disponibles"
        IMPROVEMENTS=$((IMPROVEMENTS + 1))
    else
        echo "  ✅ Version Bash >= 4.4"
    fi
fi

# Vérifier les dépendances
check_dependency() {
    local cmd="$1"
    local min_version="$2"
    
    if command -v "$cmd" >/dev/null 2>&1; then
        local version
        version=$($cmd --version 2>&1 | head -1 | grep -o '[0-9]\+\.[0-9]\+' | head -1 || echo "unknown")
        echo "  ✅ $cmd: $version"
    else
        echo "  ❌ $cmd: non installé"
        IMPROVEMENTS=$((IMPROVEMENTS + 1))
    fi
}

echo ""
echo "Dépendances:"
check_dependency "git" "2.0"
check_dependency "jq" "1.5"
check_dependency "curl" "7.0"

echo ""
echo "=== Recommandations ==="
echo ""
echo "1. Remplacer tous les 'echo' par 'log_*' approprié"
echo "2. Marquer les constantes comme 'readonly'"
echo "3. Documenter toutes les fonctions"
echo "4. Utiliser 'local -r' pour les variables locales readonly"
echo "5. Utiliser 'mapfile' au lieu de 'while read' pour les tableaux"
echo "6. Vérifier les race conditions en mode parallèle"
echo ""
echo "Total améliorations identifiées: $IMPROVEMENTS"
echo ""
