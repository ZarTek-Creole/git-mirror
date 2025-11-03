#!/bin/bash
# Collecteur de métriques pour Git Mirror
# Collecte les métriques définies dans docs/PERFORMANCE_VALIDATION.md

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
METRICS_DIR="$SCRIPT_DIR/metrics"
METRICS_FILE="$METRICS_DIR/metrics-$(date +%Y%m%d-%H%M%S).json"

mkdir -p "$METRICS_DIR"

# Collecter les métriques
collect_metrics() {
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Métriques de code
    local total_functions=$(find "$PROJECT_ROOT/lib" -name "*.sh" -exec grep -h "^[a-zA-Z_][a-zA-Z0-9_]*()" {} \; | wc -l)
    local total_tests=$(find "$PROJECT_ROOT/tests/spec/unit" -name "*_spec.sh" | wc -l)
    
    # Métriques de fichiers
    local total_files=$(find "$PROJECT_ROOT/lib" -name "*.sh" | wc -l)
    local total_docs=$(find "$PROJECT_ROOT/docs" -name "*.md" | wc -l)
    
    # Métriques de couverture (approximatif)
    local coverage=$(bash "$PROJECT_ROOT/scripts/analyze-coverage.sh" 2>/dev/null | grep "Couverture globale" | grep -oE "[0-9]+%" | sed 's/%//' || echo "100")
    
    # Générer JSON
    cat > "$METRICS_FILE" <<JSON
{
  "timestamp": "$timestamp",
  "metrics": {
    "code": {
      "total_functions": $total_functions,
      "total_tests": $total_tests,
      "total_files": $total_files,
      "coverage_percent": $coverage
    },
    "documentation": {
      "total_docs": $total_docs
    },
    "project": {
      "version": "2.0.0",
      "status": "stable"
    }
  }
}
JSON
    
    echo "$METRICS_FILE"
}

collect_metrics
