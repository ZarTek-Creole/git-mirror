#!/bin/bash
# hooks/example_post_clone.sh - Exemple de hook post-clonage
# Description: Ce hook est exécuté après le clonage réussi d'un dépôt

set -euo pipefail

# Arguments passés par git-mirror
REPO_NAME="$1"
REPO_PATH="$2"
REPO_URL="$3"

# Exemple 1: Lancer des tests automatiques après le clonage
echo "Running tests for $REPO_NAME..."
cd "$REPO_PATH" || exit

if [ -f "package.json" ]; then
    npm test || echo "Tests failed (non-blocking)"
fi

# Exemple 2: Installer des dépendances spécifiques
if [ -f "requirements.txt" ]; then
    pip install -q -r requirements.txt || true
fi

# Exemple 3: Créer un lien symbolique dans un répertoire custom
ln -sf "$REPO_PATH" "/opt/projects/$REPO_NAME" || true

echo "✓ Post-clone hook completed for $REPO_NAME"

