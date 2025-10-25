#!/usr/bin/env bash
# Test Helper pour les tests unitaires Git Mirror
# Description: Fonctions utilitaires pour les tests
# Author: ZarTek-Creole
# Date: 2025-10-25

# Configuration des tests
export TEST_MODE=true
export VERBOSE=0

# Charger les modules nécessaires
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Charger tous les modules dans l'ordre correct
source "$SCRIPT_DIR/lib/logging/logger.sh"
source "$SCRIPT_DIR/config/config.sh"
source "$SCRIPT_DIR/lib/auth/auth.sh"
source "$SCRIPT_DIR/lib/api/github_api.sh"
source "$SCRIPT_DIR/lib/validation/validation.sh"
source "$SCRIPT_DIR/lib/git/git_ops.sh"
source "$SCRIPT_DIR/lib/cache/cache.sh"
source "$SCRIPT_DIR/lib/parallel/parallel.sh"
source "$SCRIPT_DIR/lib/filters/filters.sh"
source "$SCRIPT_DIR/lib/metrics/metrics.sh"
source "$SCRIPT_DIR/lib/interactive/interactive.sh"
source "$SCRIPT_DIR/lib/state/state.sh"
source "$SCRIPT_DIR/lib/incremental/incremental.sh"

# Charger les utilitaires de mock
source "$SCRIPT_DIR/tests/utils/mock.sh"

# Fonctions utilitaires pour les tests
setup_test_env() {
    export TEST_MODE=true
    export VERBOSE=0
}

cleanup_test_env() {
    unset TEST_MODE VERBOSE
}
