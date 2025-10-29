#!/bin/bash
# Configuration: Git Mirror Configuration
# Description: Configuration centralisée pour le script git-mirror
# Pattern: Singleton + Builder
# Author: ZarTek-Creole
# Date: 2025-10-25

# Configuration de sécurité
set -euo pipefail

# Vérifier si le module est déjà chargé
if [ "${CONFIG_MODULE_LOADED:-false}" = "true" ]; then
    return 0
fi

# Variables readonly pour la sécurité
readonly CONFIG_VERSION="1.0.0"
readonly CONFIG_MODULE_NAME="git_mirror_config"
readonly CONFIG_MODULE_LOADED="true"

# Configuration par défaut (readonly)
readonly DEFAULT_DEST_DIR="./repositories"
readonly DEFAULT_TIMEOUT=30
readonly DEFAULT_DEPTH=1
readonly DEFAULT_VERBOSE=0
readonly CONFIG_CACHE_TTL=3600
readonly CONFIG_PARALLEL_JOBS=1
readonly DEFAULT_MAX_RETRIES=3
readonly DEFAULT_RETRY_DELAY=2

# Variables de configuration globales
DEST_DIR="$DEFAULT_DEST_DIR"
BRANCH=""
FILTER=""
NO_CHECKOUT=false
SINGLE_BRANCH=false
DEPTH="$DEFAULT_DEPTH"
VERBOSE="$DEFAULT_VERBOSE"
QUIET=false
DRY_RUN=false
SKIP_COUNT=false
TIMEOUT_CUSTOM="$DEFAULT_TIMEOUT"
RESUME=false
PARALLEL_JOBS="$CONFIG_PARALLEL_JOBS"
INCREMENTAL=false
CACHE_DIR=".git-mirror-cache"
CACHE_TTL="$CONFIG_CACHE_TTL"
STATE_FILE=".git-mirror-state.json"
export REPO_TYPE="all"
export EXCLUDE_FORKS=false

# Variables d'authentification
AUTH_METHOD="auto"
AUTH_TOKEN=""
AUTH_SSH_KEY=""
AUTH_USERNAME=""

# Variables de contexte
context=""
username_or_orgname=""

# Variables de fonctionnalités
export PARALLEL_ENABLED=false
export FILTER_ENABLED=false
export METRICS_ENABLED=false
export EXCLUDE_PATTERNS=()
export INCLUDE_PATTERNS=()
export EXCLUDE_FILE=""
export INCLUDE_FILE=""
export INTERACTIVE_MODE=false
export CONFIRM_MODE=false
export AUTO_YES=false

# Obtenir les informations du module configuration
get_config_module_info() {
    echo "Module: $CONFIG_MODULE_NAME"
    echo "Configuration par défaut chargée"
    echo "Retry max: $DEFAULT_MAX_RETRIES"
    echo "Retry delay: $DEFAULT_RETRY_DELAY secondes"
    echo "Skip count: $SKIP_COUNT"
    echo "Fichier d'état: $STATE_FILE"
    echo "Token auth: ${AUTH_TOKEN:+défini}"
    echo "Clé SSH: ${AUTH_SSH_KEY:+définie}"
}

# Interface publique du module Configuration (Facade Pattern)
init_config() {
    log_debug "Configuration initialisée"
    _load_environment_variables
    _validate_configuration
}

# Charger les variables d'environnement
_load_environment_variables() {
    # Variables d'authentification
    if [ -n "${GITHUB_TOKEN:-}" ]; then
        AUTH_TOKEN="$GITHUB_TOKEN"
        log_debug "Token GitHub chargé depuis l'environnement"
    fi
    
    if [ -n "${GITHUB_SSH_KEY:-}" ]; then
        AUTH_SSH_KEY="$GITHUB_SSH_KEY"
        log_debug "Clé SSH chargée depuis l'environnement"
    fi
    
    if [ -n "${GITHUB_AUTH_METHOD:-}" ]; then
        AUTH_METHOD="$GITHUB_AUTH_METHOD"
        log_debug "Méthode d'authentification forcée: $AUTH_METHOD"
    fi
    
    # Variables de configuration
    if [ -n "${GIT_MIRROR_DEST_DIR:-}" ]; then
        DEST_DIR="$GIT_MIRROR_DEST_DIR"
        log_debug "Répertoire de destination chargé depuis l'environnement: $DEST_DIR"
    fi
    
    if [ -n "${GIT_MIRROR_CACHE_TTL:-}" ]; then
        CACHE_TTL="$GIT_MIRROR_CACHE_TTL"
        log_debug "TTL du cache chargé depuis l'environnement: $CACHE_TTL"
    fi
    
    if [ -n "${GIT_MIRROR_PARALLEL_JOBS:-}" ]; then
        PARALLEL_JOBS="$GIT_MIRROR_PARALLEL_JOBS"
        log_debug "Jobs parallèles chargés depuis l'environnement: $PARALLEL_JOBS"
    fi
}

# Valider la configuration
_validate_configuration() {
    local validation_failed=false
    
    # Valider les paramètres numériques
    if ! [[ "$DEPTH" =~ ^[0-9]+$ ]] || [ "$DEPTH" -lt 0 ] || [ "$DEPTH" -gt 1000 ]; then
        log_error "Profondeur invalide: $DEPTH (doit être entre 0 et 1000)"
        validation_failed=true
    fi
    
    if ! [[ "$VERBOSE" =~ ^[0-9]+$ ]] || [ "$VERBOSE" -lt 0 ] || [ "$VERBOSE" -gt 3 ]; then
        log_error "Niveau de verbosité invalide: $VERBOSE (doit être entre 0 et 3)"
        validation_failed=true
    fi
    
    if ! [[ "$PARALLEL_JOBS" =~ ^[0-9]+$ ]] || [ "$PARALLEL_JOBS" -lt 1 ] || [ "$PARALLEL_JOBS" -gt 50 ]; then
        log_error "Nombre de jobs parallèles invalide: $PARALLEL_JOBS (doit être entre 1 et 50)"
        validation_failed=true
    fi
    
    if ! [[ "$CACHE_TTL" =~ ^[0-9]+$ ]] || [ "$CACHE_TTL" -lt 60 ] || [ "$CACHE_TTL" -gt 86400 ]; then
        log_error "TTL du cache invalide: $CACHE_TTL (doit être entre 60 et 86400 secondes)"
        validation_failed=true
    fi
    
    if ! [[ "$TIMEOUT_CUSTOM" =~ ^[0-9]+$ ]] || [ "$TIMEOUT_CUSTOM" -lt 1 ] || [ "$TIMEOUT_CUSTOM" -gt 3600 ]; then
        log_error "Timeout invalide: $TIMEOUT_CUSTOM (doit être entre 1 et 3600 secondes)"
        validation_failed=true
    fi
    
    if [ "$validation_failed" = true ]; then
        log_fatal "Configuration invalide"
    fi
    
    log_debug "Configuration validée avec succès"
}

# Obtenir la configuration complète
get_config() {
    echo "=== Configuration Git Mirror ==="
    echo "Répertoire de destination: $DEST_DIR"
    echo "Contexte: $context"
    echo "Utilisateur/Organisation: $username_or_orgname"
    echo "Profondeur: $DEPTH"
    echo "Single branch: $SINGLE_BRANCH"
    echo "No checkout: $NO_CHECKOUT"
    echo "Mode verbeux: $VERBOSE"
    echo "Mode silencieux: $QUIET"
    echo "Mode dry-run: $DRY_RUN"
    echo "Mode resume: $RESUME"
    echo "Mode incrémental: $INCREMENTAL"
    echo "Jobs parallèles: $PARALLEL_JOBS"
    echo "Authentification: $AUTH_METHOD"
    echo "Cache TTL: ${CACHE_TTL}s"
    echo "Timeout: ${TIMEOUT_CUSTOM}s"
    [ -n "$AUTH_USERNAME" ] && echo "Utilisateur authentifié: $AUTH_USERNAME"
    echo "================================"
}

# Obtenir la configuration pour l'affichage de l'aide
get_config_help() {
    echo "Configuration par défaut:"
    echo "  Répertoire de destination: $DEFAULT_DEST_DIR"
    echo "  Profondeur: $DEFAULT_DEPTH"
    echo "  Jobs parallèles: $CONFIG_PARALLEL_JOBS"
    echo "  Cache TTL: ${CONFIG_CACHE_TTL}s"
    echo "  Timeout: ${DEFAULT_TIMEOUT}s"
    echo ""
    echo "Variables d'environnement:"
    echo "  GITHUB_TOKEN              Token d'accès personnel GitHub"
    echo "  GITHUB_SSH_KEY            Chemin vers la clé SSH privée"
    echo "  GITHUB_AUTH_METHOD        Force la méthode d'authentification (token/ssh/public)"
    echo "  GIT_MIRROR_DEST_DIR       Répertoire de destination par défaut"
    echo "  GIT_MIRROR_CACHE_TTL      TTL du cache en secondes"
    echo "  GIT_MIRROR_PARALLEL_JOBS  Nombre de jobs parallèles par défaut"
}

# Sauvegarder la configuration dans un fichier
save_config() {
    local config_file="${1:-.git-mirror-config.json}"
    
    local config_json
    config_json=$(cat <<EOF
{
  "version": "$CONFIG_VERSION",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "configuration": {
    "dest_dir": "$DEST_DIR",
    "branch": "$BRANCH",
    "filter": "$FILTER",
    "no_checkout": $NO_CHECKOUT,
    "single_branch": $SINGLE_BRANCH,
    "depth": $DEPTH,
    "verbose": $VERBOSE,
    "quiet": $QUIET,
    "dry_run": $DRY_RUN,
    "resume": $RESUME,
    "parallel_jobs": $PARALLEL_JOBS,
    "incremental": $INCREMENTAL,
    "cache_dir": "$CACHE_DIR",
    "cache_ttl": $CACHE_TTL,
    "timeout": $TIMEOUT_CUSTOM,
    "auth_method": "$AUTH_METHOD",
    "auth_username": "$AUTH_USERNAME"
  },
  "context": {
    "type": "$context",
    "target": "$username_or_orgname"
  }
}
EOF
)
    
    echo "$config_json" > "$config_file" 2>/dev/null || {
        log_error "Impossible de sauvegarder la configuration: $config_file"
        return 1
    }
    
    log_debug "Configuration sauvegardée: $config_file"
    return 0
}

# Charger la configuration depuis un fichier
load_config() {
    local config_file="${1:-.git-mirror-config.json}"
    
    if [ ! -f "$config_file" ]; then
        log_warning "Fichier de configuration inexistant: $config_file"
        return 1
    fi
    
    # Charger les valeurs depuis le JSON (nécessite jq)
    if command -v jq >/dev/null 2>&1; then
        DEST_DIR=$(jq -r '.configuration.dest_dir // "'"$DEFAULT_DEST_DIR"'"' "$config_file")
        BRANCH=$(jq -r '.configuration.branch // ""' "$config_file")
        FILTER=$(jq -r '.configuration.filter // ""' "$config_file")
        NO_CHECKOUT=$(jq -r '.configuration.no_checkout // false' "$config_file")
        SINGLE_BRANCH=$(jq -r '.configuration.single_branch // false' "$config_file")
        DEPTH=$(jq -r '.configuration.depth // '"$DEFAULT_DEPTH" "$config_file")
        VERBOSE=$(jq -r '.configuration.verbose // '"$DEFAULT_VERBOSE" "$config_file")
        QUIET=$(jq -r '.configuration.quiet // false' "$config_file")
        DRY_RUN=$(jq -r '.configuration.dry_run // false' "$config_file")
        RESUME=$(jq -r '.configuration.resume // false' "$config_file")
        PARALLEL_JOBS=$(jq -r '.configuration.parallel_jobs // '"$CONFIG_PARALLEL_JOBS" "$config_file")
        INCREMENTAL=$(jq -r '.configuration.incremental // false' "$config_file")
        CACHE_DIR=$(jq -r '.configuration.cache_dir // ".git-mirror-cache"' "$config_file")
        CACHE_TTL=$(jq -r '.configuration.cache_ttl // '"$DEFAULT_CACHE_TTL" "$config_file")
        TIMEOUT_CUSTOM=$(jq -r '.configuration.timeout // '"$DEFAULT_TIMEOUT" "$config_file")
        AUTH_METHOD=$(jq -r '.configuration.auth_method // "auto"' "$config_file")
        AUTH_USERNAME=$(jq -r '.configuration.auth_username // ""' "$config_file")
        
        context=$(jq -r '.context.type // ""' "$config_file")
        username_or_orgname=$(jq -r '.context.target // ""' "$config_file")
        
        log_debug "Configuration chargée depuis: $config_file"
        return 0
    else
        log_error "jq requis pour charger la configuration JSON"
        return 1
    fi
}

# Réinitialiser la configuration aux valeurs par défaut
reset_config() {
    DEST_DIR="$DEFAULT_DEST_DIR"
    BRANCH=""
    FILTER=""
    NO_CHECKOUT=false
    SINGLE_BRANCH=false
    DEPTH="$DEFAULT_DEPTH"
    VERBOSE="$DEFAULT_VERBOSE"
    QUIET=false
    DRY_RUN=false
    TIMEOUT_CUSTOM="$DEFAULT_TIMEOUT"
    RESUME=false
    PARALLEL_JOBS="$CONFIG_PARALLEL_JOBS"
    INCREMENTAL=false
    CACHE_DIR=".git-mirror-cache"
    CACHE_TTL="$CONFIG_CACHE_TTL"
    STATE_FILE=".git-mirror-state.json"
    
    AUTH_METHOD="auto"
    AUTH_TOKEN=""
    AUTH_SSH_KEY=""
    AUTH_USERNAME=""
    
    context=""
    username_or_orgname=""
    
    log_debug "Configuration réinitialisée aux valeurs par défaut"
}

# Export des fonctions publiques
export -f init_config get_config get_config_help save_config load_config reset_config

# Initialisation automatique du module (si logger disponible)
if command -v log_debug >/dev/null 2>&1; then
    init_config
else
    # Initialisation sans logger
    _load_environment_variables
    _validate_configuration
fi
