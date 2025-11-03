#!/bin/bash
# Script pour trouver précisément les fonctions non testées

set -euo pipefail

LIB_DIR="/workspace/lib"
TESTS_DIR="/workspace/tests/spec/unit"

extract_functions() {
    local file="$1"
    grep -E '^[a-zA-Z_][a-zA-Z0-9_]*\(\)' "$file" 2>/dev/null | sed 's/()$//' | sed 's/()\s*{.*//' | sort -u
}

extract_tested() {
    local test_file="$1"
    grep -E "(When call |Describe ')[a-zA-Z_][a-zA-Z0-9_]*\(" "$test_file" 2>/dev/null | \
        sed -E 's/.*(When call |Describe '"'"')([a-zA-Z_][a-zA-Z0-9_]*)\(.*/\2/' | sort -u
}

for mod_file in "$LIB_DIR"/*/*.sh; do
    mod=$(basename "$mod_file" .sh)
    test_file="$TESTS_DIR/test_${mod}_spec.sh"
    
    if [ "$mod" = "github_api" ]; then
        test_file="$TESTS_DIR/test_api_spec.sh"
    elif [ "$mod" = "parallel_optimized" ]; then
        test_file="$TESTS_DIR/test_parallel_optimized_spec.sh"
    fi
    
    if [ ! -f "$test_file" ]; then
        test_file=$(find "$TESTS_DIR" -name "*${mod}*_spec.sh" 2>/dev/null | head -1)
    fi
    
    funcs=$(extract_functions "$mod_file")
    tested=""
    if [ -f "$test_file" ]; then
        tested=$(extract_tested "$test_file")
    fi
    
    untested=$(comm -23 <(echo "$funcs") <(echo "$tested"))
    if [ -n "$untested" ]; then
        echo "=== $mod ==="
        echo "$untested" | sed 's/^/  - /'
        echo ""
    fi
done
