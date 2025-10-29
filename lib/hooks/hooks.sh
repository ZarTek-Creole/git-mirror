#!/bin/bash
# lib/hooks/hooks.sh - Module de hooks post-clonage
# Description: Hooks pour exécuter des actions après le clonage/mise à jour

set -euo pipefail

# Variables de configuration
HOOKS_ENABLED="${HOOKS_ENABLED:-false}"
HOOKS_DIR="${HOOKS_DIR:-$SCRIPT_DIR/hooks}"
HOOKS_CONFIG="${HOOKS_CONFIG:-}"

# Tableaux pour stocker les hooks
declare -a HOOKS_POST_CLONE=()
declare -a HOOKS_POST_UPDATE=()
declare -a HOOKS_ON_ERROR=()

# Charger les hooks depuis la configuration
load_hooks_config() {
    if [ -z "$HOOKS_CONFIG" ] || [ ! -f "$HOOKS_CONFIG" ]; then
        return 0
    fi
    
    log_debug "Chargement de la configuration des hooks: $HOOKS_CONFIG"
    
    # Parser la configuration des hooks (format simple)
    while IFS='=' read -r key value; do
        # Ignorer les commentaires et lignes vides
        [[ "$key" =~ ^# ]] && continue
        [[ -z "$key" ]] && continue
        
        case "$key" in
            POST_CLONE)
                HOOKS_POST_CLONE+=("$value")
                ;;
            POST_UPDATE)
                HOOKS_POST_UPDATE+=("$value")
                ;;
            ON_ERROR)
                HOOKS_ON_ERROR+=("$value")
                ;;
        esac
    done < "$HOOKS_CONFIG"
    
    log_info "Hooks chargés: ${#HOOKS_POST_CLONE[@]} post-clone, ${#HOOKS_POST_UPDATE[@]} post-update, ${#HOOKS_ON_ERROR[@]} on-error"
}

# Exécuter les hooks post-clonage
execute_post_clone_hooks() {
    local repo_name="$1"
    local repo_path="$2"
    local repo_url="$3"
    
    if [ "$HOOKS_ENABLED" != "true" ] || [ "${#HOOKS_POST_CLONE[@]}" -eq 0 ]; then
        return 0
    fi
    
    log_debug "Exécution des hooks post-clonage pour: $repo_name"
    
    for hook in "${HOOKS_POST_CLONE[@]}"; do
        if [ ! -x "$hook" ]; then
            log_warning "Hook non exécutable ou inexistant: $hook"
            continue
        fi
        
        log_info "Exécution du hook: $hook"
        
        if bash "$hook" "$repo_name" "$repo_path" "$repo_url"; then
            log_success "Hook réussi: $hook"
        else
            log_warning "Hook échoué: $hook (non bloquant)"
        fi
    done
}

# Exécuter les hooks post-mise à jour
execute_post_update_hooks() {
    local repo_name="$1"
    local repo_path="$2"
    local repo_url="$3"
    
    if [ "$HOOKS_ENABLED" != "true" ] || [ "${#HOOKS_POST_UPDATE[@]}" -eq 0 ]; then
        return 0
    fi
    
    log_debug "Exécution des hooks post-update pour: $repo_name"
    
    for hook in "${HOOKS_POST_UPDATE[@]}"; do
        if [ ! -x "$hook" ]; then
            log_warning "Hook non exécutable ou inexistant: $hook"
            continue
        fi
        
        log_info "Exécution du hook: $hook"
        
        if bash "$hook" "$repo_name" "$repo_path" "$repo_url"; then
            log_success "Hook réussi: $hook"
        else
            log_warning "Hook échoué: $hook (non bloquant)"
        fi
    done
}

# Exécuter les hooks en cas d'erreur
execute_on_error_hooks() {
    local repo_name="$1"
    local repo_path="$2"
    local repo_url="$3"
    local error_msg="$4"
    
    if [ "$HOOKS_ENABLED" != "true" ] || [ "${#HOOKS_ON_ERROR[@]}" -eq 0 ]; then
        return 0
    fi
    
    log_debug "Exécution des hooks on-error pour: $repo_name"
    
    for hook in "${HOOKS_ON_ERROR[@]}"; do
        if [ ! -x "$hook" ]; then
            log_warning "Hook non exécutable ou inexistant: $hook"
            continue
        fi
        
        log_info "Exécution du hook d'erreur: $hook"
        
        if bash "$hook" "$repo_name" "$repo_path" "$repo_url" "$error_msg"; then
            log_success "Hook d'erreur réussi: $hook"
        else
            log_warning "Hook d'erreur échoué: $hook (non bloquant)"
        fi
    done
}

# Initialiser le module de hooks
hooks_init() {
    if [ "$HOOKS_ENABLED" = "true" ]; then
        load_hooks_config
        
        if [ ! -d "$HOOKS_DIR" ]; then
            mkdir -p "$HOOKS_DIR"
            log_info "Répertoire de hooks créé: $HOOKS_DIR"
        fi
        
        log_success "Module de hooks initialisé"
    else
        log_debug "Module de hooks désactivé"
    fi
    
    return 0
}

# Exporter les fonctions
export -f load_hooks_config execute_post_clone_hooks execute_post_update_hooks execute_on_error_hooks hooks_init

