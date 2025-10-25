#!/bin/bash
# Module: Validation
# Description: Validation des paramètres et données d'entrée
# Pattern: Strategy + Chain of Responsibility
# Author: ZarTek-Creole
# Date: 2025-10-25

# Configuration de sécurité
set -euo pipefail

# Vérifier si le module est déjà chargé
if [ "${VALIDATION_MODULE_LOADED:-false}" = "true" ]; then
    return 0
fi

# Variables readonly pour la sécurité
readonly VALIDATION_VERSION="1.0.0"
readonly VALIDATION_MODULE_NAME="validation"
readonly VALIDATION_MODULE_LOADED="true"

# Obtenir les informations du module validation
get_validation_module_info() {
    echo "Module: $VALIDATION_MODULE_NAME v$VALIDATION_VERSION"
    echo "Fonctions de validation disponibles: context, destination, branch, filter, depth, parallel_jobs, timeout"
}

# Interface publique du module Validation (Facade Pattern)
init_validation() {
    log_debug "Module de validation initialisé"
}

# Validation du contexte (users/orgs)
validate_context() {
    local context="$1"
    
    case "$context" in
        "users"|"orgs")
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Validation du nom d'utilisateur/organisation
validate_username() {
    local username="$1"
    
    # Vérifier que le nom n'est pas vide
    if [ -z "$username" ]; then
        return 1
    fi
    
    # Vérifier la longueur (GitHub limite à 39 caractères)
    if [ ${#username} -gt 39 ]; then
        return 1
    fi
    
    # Vérifier les caractères autorisés (alphanumériques et tirets)
    if ! [[ "$username" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$ ]] && ! [[ "$username" =~ ^[a-zA-Z0-9]$ ]]; then
        return 1
    fi
    
    return 0
}

# Validation du répertoire de destination
validate_destination() {
    local dest_dir="$1"
    
    # Vérifier que le chemin n'est pas vide
    if [ -z "$dest_dir" ]; then
        return 1
    fi
    
    # Vérifier que le chemin est absolu ou relatif valide
    if [[ "$dest_dir" =~ ^/ ]]; then
        # Chemin absolu
        local parent_dir
        parent_dir=$(dirname "$dest_dir")
        if [ ! -d "$parent_dir" ]; then
            return 1
        fi
        if [ ! -w "$parent_dir" ]; then
            return 1
        fi
    else
        # Chemin relatif - vérifier le répertoire courant
        if [ ! -w "." ]; then
            return 1
        fi
    fi
    
    return 0
}

# Validation de la branche
validate_branch() {
    local branch="$1"
    
    # Si vide, c'est valide (branche par défaut)
    if [ -z "$branch" ]; then
        return 0
    fi
    
    # Vérifier la longueur (Git limite à 255 caractères)
    if [ ${#branch} -gt 255 ]; then
        return 1
    fi
    
    # Vérifier les caractères interdits
    if [[ "$branch" =~ [~^:\[\]\\] ]] || [[ "$branch" =~ \.\. ]] || [[ "$branch" =~ @\{ ]]; then
        return 1
    fi
    
    # Vérifier qu'il ne se termine pas par un point
    if [[ "$branch" =~ \.$ ]]; then
        return 1
    fi
    
    return 0
}

# Validation du filtre Git
validate_filter() {
    local filter="$1"
    
    # Si vide, c'est valide (pas de filtre)
    if [ -z "$filter" ]; then
        return 0
    fi
    
    # Vérifier les filtres Git valides
    case "$filter" in
        "blob:none"|"tree:0"|"sparse:oid="*)
            return 0
            ;;
        *)
            log_warning "Filtre Git potentiellement invalide: $filter"
            # Ne pas échouer, juste avertir
            return 0
            ;;
    esac
}

# Validation de la profondeur
validate_depth() {
    local depth="$1"
    
    # Vérifier que c'est un nombre positif
    if ! [[ "$depth" =~ ^[0-9]+$ ]]; then
        return 1
    fi
    
    # Vérifier la plage (1-1000)
    if [ "$depth" -lt 1 ] || [ "$depth" -gt 1000 ]; then
        return 1
    fi
    
    return 0
}

# Validation du nombre de jobs parallèles
validate_parallel_jobs() {
    local jobs="$1"
    
    # Vérifier que c'est un nombre positif
    if ! [[ "$jobs" =~ ^[0-9]+$ ]]; then
        return 1
    fi
    
    # Vérifier la plage (1-50)
    if [ "$jobs" -lt 1 ] || [ "$jobs" -gt 50 ]; then
        return 1
    fi
    
    return 0
}

# Validation du timeout
validate_timeout() {
    local timeout="$1"
    
    # Si vide, c'est valide (timeout par défaut)
    if [ -z "$timeout" ]; then
        return 0
    fi
    
    # Vérifier que c'est un nombre positif
    if ! [[ "$timeout" =~ ^[0-9]+$ ]]; then
        return 1
    fi
    
    # Vérifier la plage (1-3600 secondes)
    if [ "$timeout" -lt 1 ] || [ "$timeout" -gt 3600 ]; then
        return 1
    fi
    
    return 0
}

# Validation d'une URL GitHub
validate_github_url() {
    local url="$1"
    
    # Vérifier le format de l'URL GitHub
    if [[ "$url" =~ ^https://github\.com/[^/]+/[^/]+\.git$ ]] || [[ "$url" =~ ^git@github\.com:[^/]+/[^/]+\.git$ ]]; then
        return 0
    else
        log_error "URL GitHub invalide: $url"
        return 1
    fi
}

# Validation des permissions de fichier
validate_file_permissions() {
    local file_path="$1"
    local expected_perms="${2:-644}"
    
    if [ ! -f "$file_path" ]; then
        log_error "Fichier inexistant: $file_path"
        return 1
    fi
    
    local current_perms
    current_perms=$(stat -c "%a" "$file_path" 2>/dev/null || echo "000")
    
    if [ "$current_perms" != "$expected_perms" ]; then
        log_warning "Permissions incorrectes pour $file_path: $current_perms (attendu: $expected_perms)"
        # Ne pas échouer, juste avertir
    fi
    
    return 0
}

# Validation des permissions de répertoire
validate_dir_permissions() {
    local dir_path="$1"
    local expected_perms="${2:-755}"
    
    if [ ! -d "$dir_path" ]; then
        log_error "Répertoire inexistant: $dir_path"
        return 1
    fi
    
    local current_perms
    current_perms=$(stat -c "%a" "$dir_path" 2>/dev/null || echo "000")
    
    if [ "$current_perms" != "$expected_perms" ]; then
        log_warning "Permissions incorrectes pour $dir_path: $current_perms (attendu: $expected_perms)"
        # Ne pas échouer, juste avertir
    fi
    
    return 0
}

# Validation complète des paramètres
validate_all_params() {
    local context="$1"
    local username="$2"
    local dest_dir="$3"
    local branch="$4"
    local filter="$5"
    local depth="$6"
    local parallel_jobs="$7"
    local timeout="$8"
    
    local validation_failed=false
    
    # Debug des paramètres reçus
    if command -v log_debug >/dev/null 2>&1; then
        log_debug "Validation des paramètres: context=$context, username=$username, dest_dir=$dest_dir, branch=$branch, filter=$filter, depth=$depth, parallel_jobs=$parallel_jobs, timeout=$timeout"
    fi
    
    # Valider chaque paramètre
    if ! validate_context "$context"; then
        validation_failed=true
    fi
    
    if ! validate_username "$username"; then
        validation_failed=true
    fi
    
    if ! validate_destination "$dest_dir"; then
        validation_failed=true
    fi
    
    if ! validate_branch "$branch"; then
        validation_failed=true
    fi
    
    if ! validate_filter "$filter"; then
        validation_failed=true
    fi
    
    if ! validate_depth "$depth"; then
        validation_failed=true
    fi
    
    if ! validate_parallel_jobs "$parallel_jobs"; then
        validation_failed=true
    fi
    
    if ! validate_timeout "$timeout"; then
        validation_failed=true
    fi
    
    if [ "$validation_failed" = true ]; then
        return 1
    fi
    
    log_debug "Validation des paramètres réussie"
    return 0
}

# Fonction principale d'initialisation du module de validation
validate_setup() {
    log_debug "Module de validation initialisé"
    return 0
}

# Export des fonctions publiques
export -f init_validation validate_context validate_username validate_destination validate_branch validate_filter validate_depth validate_parallel_jobs validate_timeout validate_github_url validate_file_permissions validate_dir_permissions validate_all_params validate_setup
