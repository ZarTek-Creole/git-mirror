#!/bin/bash
# Module: Logger
# Description: Système de logging modulaire avec niveaux et couleurs
# Pattern: Facade + Strategy
# Author: ZarTek-Creole
# Date: 2025-10-25

# Configuration de sécurité
set -euo pipefail

# Vérifier si le module est déjà chargé
if [ "${LOGGER_MODULE_LOADED:-false}" = "true" ]; then
    return 0
fi

# Variables readonly pour la sécurité
readonly LOGGER_VERSION="1.0.0"
readonly LOGGER_MODULE_NAME="logger"
readonly LOGGER_MODULE_LOADED="true"

# Couleurs pour les messages (readonly pour la sécurité)
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Niveaux de log (readonly)
readonly LOG_LEVEL_ERROR=1
readonly LOG_LEVEL_WARNING=2
readonly LOG_LEVEL_INFO=3
readonly LOG_LEVEL_SUCCESS=4
readonly LOG_LEVEL_DEBUG=5
readonly LOG_LEVEL_TRACE=6
readonly LOG_LEVEL_DRY_RUN=7

# Variables globales du module (initialisées par init_logger)
VERBOSE_LEVEL=0
QUIET_MODE=false
DRY_RUN_MODE=false
LOG_TIMESTAMP=true

# Obtenir les informations du module logger
get_logger_module_info() {
    echo "Module: $LOGGER_MODULE_NAME"
    echo "Niveaux de log disponibles:"
    echo "  ERROR: $LOG_LEVEL_ERROR"
    echo "  WARNING: $LOG_LEVEL_WARNING"
    echo "  INFO: $LOG_LEVEL_INFO"
    echo "  SUCCESS: $LOG_LEVEL_SUCCESS"
    echo "  DEBUG: $LOG_LEVEL_DEBUG"
    echo "  TRACE: $LOG_LEVEL_TRACE"
    echo "  DRY-RUN: $LOG_LEVEL_DRY_RUN"
}

# Interface publique du module Logger (Facade Pattern)
init_logger() {
    local verbose_level="${1:-0}"
    local quiet_mode="${2:-false}"
    local dry_run_mode="${3:-false}"
    local timestamp="${4:-true}"
    
    # Validation paramètres
    if ! [[ "$verbose_level" =~ ^[0-9]+$ ]]; then
        echo "init_logger: verbose_level doit être un nombre (reçu: '$verbose_level')" >&2
        return 1
    fi
    
    if ! [[ "$quiet_mode" =~ ^(true|false)$ ]]; then
        echo "init_logger: quiet_mode doit être 'true' ou 'false' (reçu: '$quiet_mode')" >&2
        return 1
    fi
    
    if ! [[ "$dry_run_mode" =~ ^(true|false)$ ]]; then
        echo "init_logger: dry_run_mode doit être 'true' ou 'false' (reçu: '$dry_run_mode')" >&2
        return 1
    fi
    
    if ! [[ "$timestamp" =~ ^(true|false)$ ]]; then
        echo "init_logger: timestamp doit être 'true' ou 'false' (reçu: '$timestamp')" >&2
        return 1
    fi
    
    VERBOSE_LEVEL="$verbose_level"
    QUIET_MODE="$quiet_mode"
    DRY_RUN_MODE="$dry_run_mode"
    LOG_TIMESTAMP="$timestamp"
    
    if [ "$VERBOSE_LEVEL" -ge 2 ]; then
        log_debug "Logger initialisé - Niveau: $VERBOSE_LEVEL, Quiet: $QUIET_MODE, Dry-run: $DRY_RUN_MODE"
    fi
}

# Fonctions de logging publiques (Strategy Pattern)
log_error() {
    if [ "$QUIET_MODE" = false ]; then
        _log_message "ERROR" "$RED" "$*"
    fi
}

log_warning() {
    if [ "$QUIET_MODE" = false ]; then
        _log_message "WARNING" "$YELLOW" "$*"
    fi
}

log_info() {
    if [ "$QUIET_MODE" = false ]; then
        _log_message "INFO" "$BLUE" "$*"
    fi
}

log_success() {
    if [ "$QUIET_MODE" = false ]; then
        _log_message "SUCCESS" "$GREEN" "$*"
    fi
}

log_debug() {
    if [ "$VERBOSE_LEVEL" -ge 2 ] && [ "$QUIET_MODE" = false ]; then
        _log_message "DEBUG" "$PURPLE" "$*" 2
    fi
}

log_trace() {
    if [ "$VERBOSE_LEVEL" -ge 3 ] && [ "$QUIET_MODE" = false ]; then
        _log_message "TRACE" "$CYAN" "$*"
    fi
}

log_dry_run() {
    if [ "$DRY_RUN_MODE" = true ] && [ "$QUIET_MODE" = false ]; then
        _log_message "DRY-RUN" "$YELLOW" "$*"
    fi
}

# Fonction interne pour formater et afficher les messages (Strategy Pattern)
_log_message() {
    local level_name="$1"
    local color="$2"
    local message="$3"
    local output_fd="${4:-1}"  # stdout par défaut, stderr si 2
    
    local timestamp_str=""
    if [ "$LOG_TIMESTAMP" = true ]; then
        timestamp_str="$(date '+%Y-%m-%d %H:%M:%S') - "
    fi
    
    echo -e "${color}[${level_name}]${NC} ${timestamp_str}${message}" >&"$output_fd"
}

# Fonction utilitaire pour les erreurs fatales
log_fatal() {
    log_error "$*"
    exit 1
}

# Fonction error() centralisée (compatibilité avec patterns standards)
# Usage: error "Message d'erreur" [exit_code]
error() {
    local message="$1"
    local exit_code="${2:-1}"
    
    log_error "$message"
    exit "$exit_code"
}

# Fonction warn() centralisée (compatibilité avec patterns standards)
warn() {
    log_warning "$*"
}

# Fonction pour afficher le statut du module
logger_status() {
    echo "Logger Module Status:"
    echo "  Version: $LOGGER_VERSION"
    echo "  Verbose Level: $VERBOSE_LEVEL"
    echo "  Quiet Mode: $QUIET_MODE"
    echo "  Dry-run Mode: $DRY_RUN_MODE"
    echo "  Timestamp: $LOG_TIMESTAMP"
}

# Fonctions de log spéciales pour stderr (pour les fonctions qui retournent des valeurs)
# Wrappers optimisés : délégation directe vers _log_message avec output_fd=2
log_error_stderr() {
    if [ "$QUIET_MODE" = false ]; then
        _log_message "ERROR" "$RED" "$*" 2
    fi
}

log_warning_stderr() {
    if [ "$QUIET_MODE" = false ]; then
        _log_message "WARNING" "$YELLOW" "$*" 2
    fi
}

log_debug_stderr() {
    if [ "$VERBOSE_LEVEL" -ge 2 ] && [ "$QUIET_MODE" = false ]; then
        _log_message "DEBUG" "$PURPLE" "$*" 2
    fi
}

log_info_stderr() {
    if [ "$QUIET_MODE" = false ]; then
        _log_message "INFO" "$BLUE" "$*" 2
    fi
}

log_success_stderr() {
    if [ "$QUIET_MODE" = false ]; then
        _log_message "SUCCESS" "$GREEN" "$*" 2
    fi
}

# Export des fonctions publiques
export -f init_logger log_error log_warning log_info log_success log_debug \
  log_trace log_dry_run log_fatal logger_status log_error_stderr \
  log_warning_stderr log_debug_stderr log_info_stderr log_success_stderr \
  error warn _log_message
