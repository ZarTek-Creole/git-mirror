#!/bin/bash
# Script pour mesurer la couverture de code avec kcov
# Usage: ./scripts/measure-coverage.sh [module]

set -euo pipefail

COVERAGE_DIR="coverage/kcov"
MODULE="${1:-}"

# Nettoyer ancienne couverture
rm -rf "$COVERAGE_DIR"

echo "🔍 Mesure de la couverture de code..."

if [ -z "$MODULE" ]; then
    echo "Exécution de tous les tests..."
    shellspec --kcov --kcov-options="--include-path=lib" tests/spec/unit/ 2>&1 | \
        grep -E "(passing|failing|examples)" || true
else
    echo "Tests=====pour module: $MODULE"
    shellspec --kcov --kcov-options="--include-path=lib" \
        tests/spec/unit/test_"${MODULE}"_spec.sh 2>&1 | \
        shellspec --count tests/spec/unit/test_"${MODULE}"_spec.sh 2>&1 || true
fi

echo ""
echo "📊 Couverture mesurée dans: $COVERAGE_DIR"

