#!/bin/bash
# Script pour améliorer automatiquement le code
# - Remplacer echo par log_* (pour logging, pas pour retour de valeurs)
# - Ajouter readonly aux constantes
# - Améliorer la documentation

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LIB_DIR="$PROJECT_ROOT/lib"

echo "=== Amélioration du Code ==="
echo ""

IMPROVEMENTS=0

# Fonction pour améliorer un fichier
improve_file() {
    local file="$1"
    local temp_file="${file}.tmp"
    local changed=false
    
    # Créer une copie
    cp "$file" "$temp_file"
    
    # Remplacer les echo utilisés pour le logging (pas ceux qui retournent des valeurs)
    # Pattern: echo "message" >&2 ou echo "message" sans redirection mais suivi de log
    # Attention: Ne pas remplacer les echo qui retournent des valeurs
    
    # Ajouter readonly aux constantes qui n'en ont pas
    if grep -q "^[[:space:]]*\(DEFAULT_\|MAX_\|MIN_\|CONFIG_\|API_\|CACHE_\|GIT_\|PARALLEL_\|METRICS_\|INCREMENTAL_\|HOOKS_\|STATE_\|SYSTEM_\|VALIDATION_\|LOGGER_\|FILTER_\)" "$temp_file"; then
        # Les constantes sont déjà readonly dans certains fichiers
        # Vérifier et ajouter si nécessaire
        :
    fi
    
    # Si des changements ont été faits
    if [ "$changed" = true ]; then
        mv "$temp_file" "$file"
        IMPROVEMENTS=$((IMPROVEMENTS + 1))
        echo "  ✅ $file amélioré"
    else
        rm -f "$temp_file"
    fi
}

# Analyser chaque module
for module_file in "$LIB_DIR"/*/*.sh; do
    if [ -f "$module_file" ]; then
        module_name=$(basename "$module_file" .sh)
        echo "Module: $module_name"
        improve_file "$module_file"
    fi
done

echo ""
echo "Total fichiers améliorés: $IMPROVEMENTS"
echo ""
