#!/bin/bash
# Script pour optimiser automatiquement les workflows GitHub Actions

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly SCRIPT_DIR
readonly WORKFLOWS_DIR="$SCRIPT_DIR"

# Couleurs
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

echo -e "${BLUE}=== Optimiseur de Workflows GitHub Actions ===${NC}"
echo ""

# Fonction pour analyser un workflow
analyze_workflow() {
    local file=$1
    local basename=$(basename "$file")
    
    echo -e "${YELLOW}Analyse: $basename${NC}"
    
    # Vérifier la syntaxe YAML
    if command -v yamllint >/dev/null 2>&1; then
        if yamllint "$file" >/dev/null 2>&1; then
            echo -e "  ${GREEN}✓${NC} Syntaxe YAML valide"
        else
            echo -e "  ${RED}✗${NC} Erreur de syntaxe YAML"
            return 1
        fi
    fi
    
    # Compter les lignes
    local lines=$(wc -l < "$file" | tr -d ' ')
    echo -e "  ${BLUE}→${NC} Lignes: $lines"
    
    # Vérifier l'utilisation des actions obsolètes
    if grep -q "checkout@v3" "$file"; then
        echo -e "  ${YELLOW}⚠${NC} Utilise checkout@v3 (obsolète)"
    elif grep -q "checkout@v4" "$file"; then
        echo -e "  ${GREEN}✓${NC} Utilise checkout@v4 (moderne)"
    fi
    
    # Vérifier les permissions
    if grep -q "^permissions:" "$file"; then
        echo -e "  ${GREEN}✓${NC} Permissions définies"
    else
        echo -e "  ${YELLOW}⚠${NC} Permissions non définies"
    fi
    
    # Vérifier les timeouts
    if grep -q "timeout-minutes:" "$file"; then
        echo -e "  ${GREEN}✓${NC} Timeout défini"
    else
        echo -e "  ${YELLOW}⚠${NC} Aucun timeout défini"
    fi
    
    echo ""
}

# Main
main() {
    echo -e "${BLUE}Analyse des workflows dans: $WORKFLOWS_DIR${NC}"
    echo ""
    
    # Trouver tous les fichiers .yml dans workflows/
    local count=0
    while IFS= read -r -d '' file; do
        if [[ "$file" != *"ARCHITECTURE.md"* ]] && \
           [[ "$file" != *"OPTIMIZATION"* ]] && \
           [[ "$file" != *"USAGE.md"* ]] && \
           [[ "$file" != *"TEST-LOCAL"* ]] && \
           [[ "$file" != *"ACT-"* ]]; then
            analyze_workflow "$file"
            count=$((count + 1))
        fi
    done < <(find "$WORKFLOWS_DIR" -maxdepth 1 -name "*.yml" -type f -print0 2>/dev/null)
    
    echo -e "${GREEN}=== ${count} workflows analysés ===${NC}"
}

main "$@"

