#!/bin/bash
# hooks/example_post_update.sh - Exemple de hook post-mise à jour
# Description: Ce hook est exécuté après la mise à jour réussie d'un dépôt

set -euo pipefail

# Arguments passés par git-mirror
REPO_NAME="$1"
REPO_PATH="$2"
REPO_URL="$3"

# Exemple 1: Synchroniser LOG avec un serveur distant
echo "Syncing $REPO_NAME to remote backup..."

rsync -aq "$REPO_PATH" /backup/repositories/ || true

# Exemple 2: Mettre à jour un fichier d'index
echo "$REPO_NAME:$(date +%s)" >> /var/log/git-mirror/last-updates.txt

# Exemple 3: Envoyer une notification (Slack, Email, etc.)
# curl -X POST "https://hooks.slack.com/services/YOUR/WEBHOOK/URL" \
#   -H 'Content-Type: application/json' \
#   -d "{\"text\": \"✅ $REPO_NAME updated successfully\"}" || true

echo "✓ Post-update hook completed for $REPO_NAME"

