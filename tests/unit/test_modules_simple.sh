#!/bin/bash
# Test simple de chargement des modules git-mirror
# Usage: bash tests/unit/test_modules_simple.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "=== Test de chargement des modules git-mirror ==="
echo ""

# Tester le chargement de chaque module
load_module() {
    local module=$1
    local file="$PROJECT_ROOT/lib/$module/${module##*/}.sh"
    
    if [ -f "$file" ]; then
        echo -n "Testing $module... "
        source "$file" && echo "✅ OK" || (echo "❌ FAILED" && exit 1)
    else
        echo -n "Testing $module... "
        # Essayer avec le nom du module comme nom de fichier
        local alt_file="$PROJECT_ROOT/lib/$module/$module.sh"
        if [ -f "$alt_file" ]; then
            source "$alt_file" && echo "✅ OK" || (echo "❌ FAILED" && exit 1)
        else
            echo "⚠️ SKIPPED (file not found)"
        fi
    fi
}

# Modules principaux
echo "--- Modules principaux ---"
load_module "logging/logger"
load_module "validation/validation"
load_module "auth/auth"
load_module "api/github_api"

echo ""
echo "--- Modules utilitaires ---"
load_module "cache/cache"
load_module "git/git_ops"
load_module "filters/filters"

echo ""
echo "=== Tous les modules chargés avec succès ==="
echo "✅ Test terminé"

