#!/bin/bash
# Script pour corriger automatiquement les lignes > 100 caractères
# Usage: ./scripts/fix-line-length.sh [fichier]

set -euo pipefail

fix_file() {
    local file="$1"
    local tmp_file="${file}.tmp"
    
    echo "Processing: $file"
    
    awk 'length > 100 {
        line = $0
        chars = length
        
        # Afficher la ligne problématique
        print "Line " NR ": " chars " chars"
    }
    {
        print
    }' "$file" > "$tmp_file"
    
    # Pour l'instant, on ne fait qu'identifier
    rm -f "$tmp_file"
}

if [ $# -eq 0 ]; then
    # Traiter tous les fichiers
    for file in $(find lib config -name "*.sh" -type f); do
        awk 'length > 100 {print FILENAME": "NR": "length" chars"}' "$file"
    done
else
    fix_file "$1"
fi

