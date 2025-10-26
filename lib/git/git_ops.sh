#!/bin/bash
# Module: Git Operations
# Description: Opérations Git avec gestion d'erreurs et retry
# Pattern: Strategy + Command + Observer
# Author: ZarTek-Creole
# Date: 2025-10-25

# Configuration de sécurité
set -euo pipefail

# Vérifier si le module est déjà chargé
if [ "${GIT_MODULE_LOADED:-false}" = "true" ]; then
    return 0
fi

# Variables readonly pour la sécurité
readonly GIT_MODULE_VERSION="1.0.0"
readonly GIT_MODULE_NAME="git_operations"
readonly GIT_MODULE_LOADED="true"

# Configuration Git
readonly MAX_GIT_RETRIES=3
readonly GIT_RETRY_DELAY=2
readonly GIT_TIMEOUT=30

# Variables globales du module
GIT_OPERATIONS_COUNT=0
GIT_SUCCESS_COUNT=0
GIT_FAILURE_COUNT=0

# Obtenir les informations du module Git
get_git_module_info() {
    echo "Module: $GIT_MODULE_NAME v$GIT_MODULE_VERSION"
    echo "Opérations Git disponibles: clone, update, fetch, pull"
}

# Interface publique du module Git (Facade Pattern)
init_git_module() {
    log_debug "Module Git initialisé"
    _reset_git_stats
}

# Cloner un dépôt avec options avancées
clone_repository() {
    local repo_url="$1"
    local dest_dir="$2"
    local branch="${3:-}"
    local depth="${4:-1}"
    local filter="${5:-}"
    local single_branch="${6:-false}"
    local no_checkout="${7:-false}"
    
    local repo_name
    repo_name=$(basename "$repo_url" .git)
    local full_dest_path="$dest_dir/$repo_name"
    
    log_info "Clonage du dépôt: $repo_name dans $full_dest_path"
    
    # Construire les options Git
    local git_opts=""
    
    # Profondeur
    if [ "$depth" != "0" ]; then
        git_opts="$git_opts --depth $depth"
    fi
    
    # Filtre
    if [ -n "$filter" ]; then
        git_opts="$git_opts --filter $filter"
    fi
    
    # Branche unique
    if [ "$single_branch" = "true" ]; then
        git_opts="$git_opts --single-branch"
        if [ -n "$branch" ]; then
            git_opts="$git_opts --branch $branch"
        fi
    fi
    
    # Pas de checkout
    if [ "$no_checkout" = "true" ]; then
        git_opts="$git_opts --no-checkout"
    fi
    
    # Submodules
    git_opts="$git_opts --recurse-submodules"
    
    # Mode verbeux
    if [ "${VERBOSE_LEVEL:-0}" -eq 0 ] && [ "${QUIET_MODE:-false}" = false ]; then
        git_opts="$git_opts --quiet"
    fi
    
    # Commande Git complète
    local git_cmd="git clone $git_opts \"$repo_url\" \"$full_dest_path\""
    
    # Exécuter avec gestion d'erreurs
    GIT_SUCCESS_COUNT=${GIT_SUCCESS_COUNT:-0}
    GIT_FAILURE_COUNT=${GIT_FAILURE_COUNT:-0}
    
    if _execute_git_command "$git_cmd" "clone"; then
        GIT_SUCCESS_COUNT=$((GIT_SUCCESS_COUNT + 1))
        log_success "Dépôt cloné avec succès: $repo_name"
        
        # Configurer safe.directory si nécessaire
        _configure_safe_directory "$full_dest_path"
        
        return 0
    else
        GIT_FAILURE_COUNT=$((GIT_FAILURE_COUNT + 1))
        log_error "Échec du clonage: $repo_name"
        return 1
    fi
}

# Mettre à jour un dépôt existant
update_repository() {
    local repo_path="$1"
    local branch="${2:-}"
    
    local repo_name
    repo_name=$(basename "$repo_path")
    
    log_info "Mise à jour du dépôt: $repo_name"
    
    # Aller dans le répertoire du dépôt
    local original_dir
    original_dir=$(pwd)
    cd "$repo_path" || return 1
    
    # Configurer safe.directory si nécessaire
    _configure_safe_directory "$repo_path"
    
    # Récupérer les dernières modifications
    local git_cmd="git fetch --all --recurse-submodules"
    if [ "${VERBOSE_LEVEL:-0}" -eq 0 ] && [ "${QUIET_MODE:-false}" = false ]; then
        git_cmd="$git_cmd --quiet"
    fi
    
    if _execute_git_command "$git_cmd" "fetch"; then
        # Mettre à jour la branche si spécifiée
        if [ -n "$branch" ]; then
            _update_branch "$branch"
        fi
        
        # Mettre à jour les submodules
        _update_submodules
        
        GIT_SUCCESS_COUNT=${GIT_SUCCESS_COUNT:-0}
        GIT_SUCCESS_COUNT=$((GIT_SUCCESS_COUNT + 1))
        log_success "Dépôt mis à jour avec succès: $repo_name"
        
        # Retourner au répertoire original
        cd "$original_dir" || return 1
        return 0
    else
        GIT_FAILURE_COUNT=${GIT_FAILURE_COUNT:-0}
        GIT_FAILURE_COUNT=$((GIT_FAILURE_COUNT + 1))
        log_error "Échec de la mise à jour: $repo_name"
        
        # Retourner au répertoire original
        cd "$original_dir" || return 1
        return 1
    fi
}

# Mettre à jour une branche spécifique
_update_branch() {
    local target_branch="$1"
    
    # Vérifier si la branche existe localement
    if git show-ref --verify --quiet "refs/heads/$target_branch"; then
        log_debug "Basculement vers la branche locale: $target_branch"
        git checkout "$target_branch" || return 1
        git pull origin "$target_branch" || return 1
    else
        # Vérifier si la branche existe sur le remote
        if git show-ref --verify --quiet "refs/remotes/origin/$target_branch"; then
            log_debug "Création de la branche locale: $target_branch"
            git checkout -b "$target_branch" "origin/$target_branch" || return 1
        else
            log_warning "Branche $target_branch non trouvée, utilisation de la branche par défaut"
            git checkout "$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')" || return 1
        fi
    fi
}

# Mettre à jour les submodules
_update_submodules() {
    if [ -f ".gitmodules" ]; then
        log_debug "Mise à jour des submodules"
        git submodule update --init --recursive || return 1
    fi
}

# Configurer safe.directory pour éviter les erreurs de propriété
_configure_safe_directory() {
    local repo_path="$1"
    
    # Vérifier si le dépôt est déjà configuré comme safe
    if ! git config --global --get-all safe.directory | grep -Fxq "$repo_path"; then
        log_debug "Configuration de safe.directory pour: $repo_path"
        git config --global --add safe.directory "$repo_path" || true
    fi
}

# Exécuter une commande Git avec retry et gestion d'erreurs
_execute_git_command() {
    local cmd="$1"
    local operation="$2"
    local retry_count=0
    
    # Initialiser GIT_OPERATIONS_COUNT si nécessaire
    GIT_OPERATIONS_COUNT=${GIT_OPERATIONS_COUNT:-0}
    GIT_OPERATIONS_COUNT=$((GIT_OPERATIONS_COUNT + 1))
    
    local max_retries="${MAX_GIT_RETRIES:-3}"
    local git_timeout="${GIT_TIMEOUT:-30}"
    local retry_delay="${GIT_RETRY_DELAY:-2}"
    while [ $retry_count -lt "$max_retries" ]; do
        if timeout "$git_timeout" bash -c "$cmd"; then
            return 0
        else
            local exit_code=$?
            retry_count=$((retry_count + 1))
            
            if [ $retry_count -lt "$max_retries" ]; then
                log_warning "Tentative $retry_count/$max_retries échouée pour $operation, retry dans ${retry_delay}s..."
                sleep "$retry_delay"
            else
                log_error "Échec définitif après $max_retries tentatives pour $operation"
                _handle_git_error "$exit_code" "$operation"
                return 1
            fi
        fi
    done
}

# Gérer les erreurs Git spécifiques
_handle_git_error() {
    local exit_code="$1"
    local operation="$2"
    
    case $exit_code in
        1)
            log_error "Erreur Git générique lors de $operation"
            ;;
        2)
            log_error "Mauvaise utilisation des commandes Git lors de $operation"
            ;;
        6|7)
            log_error "Erreur réseau lors de $operation"
            ;;
        13)
            log_error "Erreur de permissions lors de $operation"
            ;;
        28)
            log_error "Timeout lors de $operation"
            ;;
        128)
            log_error "Erreur de propriété douteuse ou dépôt non trouvé lors de $operation"
            ;;
        130)
            log_error "Opération Git interrompue lors de $operation"
            ;;
        141)
            log_error "Pipe cassé lors de $operation"
            ;;
        143)
            log_error "Espace disque insuffisant lors de $operation"
            ;;
        *)
            log_error "Erreur Git inconnue (code $exit_code) lors de $operation"
            ;;
    esac
}

# Vérifier si un dépôt existe localement
repository_exists() {
    local repo_path="$1"
    
    if [ -d "$repo_path" ] && [ -d "$repo_path/.git" ]; then
        return 0
    else
        return 1
    fi
}

# Obtenir la branche actuelle d'un dépôt
get_current_branch() {
    local repo_path="$1"
    
    if [ -d "$repo_path/.git" ]; then
        cd "$repo_path" && git branch --show-current 2>/dev/null || echo ""
    else
        echo ""
    fi
}

# Obtenir le dernier commit d'un dépôt
get_last_commit() {
    local repo_path="$1"
    
    if [ -d "$repo_path/.git" ]; then
        cd "$repo_path" && git log -1 --format="%H %cd" 2>/dev/null || echo ""
    else
        echo ""
    fi
}

# Nettoyer un dépôt corrompu
clean_corrupted_repository() {
    local repo_path="$1"
    
    log_warning "Nettoyage du dépôt corrompu: $repo_path"
    
    # Supprimer les fichiers de verrou
    find "$repo_path" -name "*.lock" -type f -delete 2>/dev/null || true
    find "$repo_path" -name "index.lock" -type f -delete 2>/dev/null || true
    
    # Supprimer le répertoire .git si nécessaire
    if [ -d "$repo_path/.git" ]; then
        rm -rf "$repo_path/.git" 2>/dev/null || true
    fi
    
    log_info "Dépôt nettoyé: $repo_path"
}

# Réinitialiser les statistiques Git
_reset_git_stats() {
    GIT_OPERATIONS_COUNT=0
    GIT_SUCCESS_COUNT=0
    GIT_FAILURE_COUNT=0
}

# Obtenir les statistiques du module Git
get_git_stats() {
    echo "Git Operations Statistics:"
    echo "  Total operations: $GIT_OPERATIONS_COUNT"
    echo "  Successful: $GIT_SUCCESS_COUNT"
    echo "  Failed: $GIT_FAILURE_COUNT"
    if [ "$GIT_OPERATIONS_COUNT" -gt 0 ]; then
        local success_rate
        success_rate=$((GIT_SUCCESS_COUNT * 100 / GIT_OPERATIONS_COUNT))
        echo "  Success rate: ${success_rate}%"
    fi
}

# Fonction principale d'initialisation du module Git
git_ops_setup() {
    init_git_module
    log_debug "Module Git initialisé"
    return 0
}

# Export des fonctions publiques
export -f init_git_module clone_repository update_repository repository_exists get_current_branch get_last_commit clean_corrupted_repository get_git_stats git_ops_setup _execute_git_command _configure_safe_directory _handle_git_error _update_submodules _update_branch
