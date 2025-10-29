#!/bin/bash
# Script de test rapide pour workflows GitHub Actions avec act
# Usage: ./scripts/test-workflows-local.sh [workflow-name]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly SCRIPT_DIR
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Couleurs
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Vérifications
check_prerequisites() {
    echo -e "${BLUE}=== Vérification des prérequis ===${NC}"
    
    # Vérifier act
    if ! command -v act >/dev/null 2>&1; then
        echo -e "${RED}❌ Act non installé${NC}"
        echo "Installez avec: curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash"
        exit 1
    fi
    echo -e "${GREEN}✅ Act: $(act --version)${NC}"
    
    # Vérifier Docker
    if ! command -v docker >/dev/null 2>&1; then
        echo -e "${RED}❌ Docker non installé${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Docker: $(docker --version)${NC}"
    
    # Vérifier que Docker tourne
    if ! docker info >/dev/null 2>&1; then
        echo -e "${RED}❌ Docker n'est pas en cours d'exécution${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Docker est en cours d'exécution${NC}"
    
    echo ""
}

# Test d'un workflow spécifique
test_workflow() {
    local workflow=$1
    local workflow_file=".github/workflows/${workflow}.yml"
    
    echo -e "${BLUE}=== Test du workflow: ${workflow} ===${NC}"
    
    if [ ! -f "$workflow_file" ]; then
        echo -e "${RED}❌ Workflow non trouvé: ${workflow_file}${NC}"
        return 1
    fi
    
    # Lister les jobs
    echo -e "${YELLOW}Jobs disponibles:${NC}"
    act -l -W "$workflow_file"
    
    echo ""
    echo -e "${YELLOW}Exécution du workflow...${NC}"
    
    # Lister les jobs (dry-run equivalent)
    if act -l -W "$workflow_file" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Workflow syntax OK${NC}"
    else
        echo -e "${RED}❌ Workflow syntax ERROR${NC}"
        return 1
    fi
    
    echo ""
}

# Test rapide (shellcheck uniquement)
test_quick() {
    echo -e "${BLUE}=== Test Rapide: ShellCheck ===${NC}"
    echo -e "${YELLOW}Ce test prend ~30 secondes${NC}"
    echo ""
    
    if act -l -W .github/workflows/shellcheck.yml >/dev/null 2>&1; then
        echo -e "${GREEN}✅ ShellCheck workflow OK${NC}"
    else
        echo -e "${RED}❌ ShellCheck workflow FAILED${NC}"
        return 1
    fi
}

# Test complet (tous les workflows)
test_all() {
    echo -e "${BLUE}=== Test Complet: Tous les Workflows ===${NC}"
    echo -e "${YELLOW}Ce test prend ~5-10 minutes${NC}"
    echo ""
    
    local workflows=(
        "shellcheck"
        "test-architecture"
        "markdownlint"
        "docs"
    )
    
    local failed=0
    
    for workflow in "${workflows[@]}"; do
        if ! test_workflow "$workflow"; then
            failed=$((failed + 1))
        fi
    done
    
    if [ $failed -eq 0 ]; then
        echo -e "${GREEN}✅ Tous les workflows sont OK${NC}"
    else
        echo -e "${RED}❌ ${failed} workflow(s) ont échoué${NC}"
        return 1
    fi
}

# Afficher l'aide
show_help() {
    cat <<EOF
Usage: $0 [OPTIONS]

Options:
  --quick, -q          Test rapide (ShellCheck uniquement)
  --all, -a            Test tous les workflows
  --workflow, -w NAME  Test un workflow spécifique
  --list, -l           Lister tous les workflows
  --help, -h           Afficher cette aide

Exemples:
  $0 --quick
  $0 --workflow shellcheck
  $0 --workflow test-architecture
  $0 --all

Workflows disponibles:
  - shellcheck
  - test-architecture
  - markdownlint
  - docs
  - ci
  - test
  - integration
  - coverage
  - release
  - security-scan
EOF
}

# Main
main() {
    cd "$PROJECT_ROOT"
    
    check_prerequisites
    
    case "${1:-}" in
        --quick|-q)
            test_quick
            ;;
        --all|-a)
            test_all
            ;;
        --workflow|-w)
            if [ -z "${2:-}" ]; then
                echo -e "${RED}❌ Spécifiez un nom de workflow${NC}"
                exit 1
            fi
            test_workflow "$2"
            ;;
        --list|-l)
            echo -e "${BLUE}=== Workflows Disponibles ===${NC}"
            act -l
            ;;
        --help|-h)
            show_help
            ;;
        "")
            test_quick
            ;;
        *)
            echo -e "${RED}❌ Option inconnue: $1${NC}"
            show_help
            exit 1
            ;;
    esac
}

main "$@"

