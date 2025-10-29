#!/bin/bash
# Script automatique pour corriger toutes les violations de longueur de ligne
# Priorise les violations les plus longues (>150 chars)

set -euo pipefail

echo "🔍 Analyse des violations restantes..."
echo ""

# Compter les violations par fichier
declare -A violations
while IFS=: read -r file line len; do
    if [ "${violations[$file]}" ]; then
        violations[$file]=$((${violations[$file]} + 1))
    else
        violations[$file]=1
    fi
done < <(find lib config -name "*.sh" -type f -exec awk 'length > 100 {print FILENAME":"NR":"length}' {} \;)

echo "📊 Violations par fichier:"
for file in "${!violations[@]}"; do
    echo "  $file: ${violations[$file]} violations"
done | sort -t: -k2 -nr

echo ""
echo "✅ Prochaine étape: Correction manuelle des violations"
echo "   Total fichiers: ${#violations[@]}"
echo "   Total violations: $(for v in "${violations[@]}"; do echo "$v"; done | awk '{sum+=$1} END {print sum}')"

