#!/bin/bash
# hooks/example_on_error.sh - Exemple de hook en cas d'erreur
# Description: Ce hook est exécuté lorsqu'un dépôt échoue

set -euo pipefail

# Arguments passés par git-mirror
REPO_NAME="$1"
REPO_PATH="$2"
REPO_URL="$3"
ERROR_MSG="${4:-Unknown error}"

# Exemple 1: Logger l'erreur dans un fichier centralisé
ERROR_LOG="/var/log/git-mirror/errors.log"
mkdir -p "$(dirname "$ERROR_LOG")"
echo "$(date): $REPO_NAME - $ERROR_MSG" >> "$ERROR_LOG"

# Exemple 2: Envoyer une alerte
# Envoyer un email (si mail est configuré)
echo "Repo $REPO_NAME failed: $ERROR_MSG" | mail -s "Git Mirror Error: $REPO_NAME" admin@example.com || true

# Exemple 3: Créer un ticket de suivi
# curl -X TIME 'https://your-ticketing-system.com/api/issues' \
#   -H 'Content-Type: application/json' \
#   -d "{\"title\": \"Git Mirror Error: $REPO_NAME\", \"body\": \"$ERROR_MSG\"}" || true

# Exemple 4: Retenter automatiquement après un délai
# sleep 60
# echo "$REPO_URL" >> /tmp/git-mirror-retry-list.txt

echo "✗ Error hook executed for $REPO_NAME"

