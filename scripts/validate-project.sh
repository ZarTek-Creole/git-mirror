#!/bin/bash
# Script de validation complète du projet
set -euo pipefail

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║          VALIDATION COMPLÈTE - GIT-MIRROR                       ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

ERRORS=0
WARNINGS=0

# Test 1: Syntaxe Bash
echo "1. Validation syntaxe Bash..."
for script in git-mirror.sh lib/*/*.sh scripts/*.sh hooks/*.sh; do
    [ -f "$script" ] || continue
    if bash -n "$script" 2>/dev/null; then
        echo "  ✅ $(basename $script)"
    else
        echo "  ❌ $(basename $script)"
        ((ERRORS++))
    fi
done

# Test 2: ShellCheck
echo ""
echo "2. ShellCheck..."
if command -v shellcheck >/dev/null 2>&1; then
    if [ -f .shellcheckrc ]; then
        shellcheck --source-path=. git-mirror.sh >/dev/null 2>&1 && echo "  ✅ git-mirror.sh" || ((WARNINGS++))
    else
        shellcheck git-mirror.sh >/dev/null 2>&1 && echo "  ✅ git-mirror.sh" || ((WARNINGS++))
    fi
else
    echo "  ⚠️ ShellCheck non installé"
fi

# Test 3: YAML
echo ""
echo "3. Validation YAML workflows..."
if command -v yamllint >/dev/null 2>&1; then
    for wf in .github/workflows/*.yml; do
        yamllint "$wf" >/dev/null 2>&1 && echo "  ✅ $(basename $wf)" || ((WARNINGS++))
    done
else
    echo "  ⚠️ yamllint non installé"
fi

# Test 4: Tests Bats
echo ""
echo "4. Tests Bats..."
if command -v bats >/dev/null 2>&1; then
    bats tests/unit/ 2>&1 | tail -1
else
    echo "  ⚠️ Bats non installé"
fi

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo "║                    ✅ VALIDATION OK                            ║"
    exit 0
else
    echo "║          ⚠️ $ERRORS erreurs, $WARNINGS warnings détectés       ║"
    exit 1
fi
echo "╚════════════════════════════════════════════════════════════════╝"
