#!/bin/bash

# Configuration de sécurité Bash
set -euo pipefail

# lib/filters/filters.sh - Module de filtrage des dépôts
# Gère l'exclusion et l'inclusion de dépôts par patterns

# Protection contre double-load du module
if [ "${FILTERS_MODULE_LOADED:-false}" = "true" ]; then
    return 0
fi

# Variables readonly pour la sécurité
readonly FILTERS_VERSION="1.0.0"
readonly FILTERS_MODULE_NAME="filters"
readonly FILTERS_MODULE_LOADED="true"

# Variables de configuration (mutables pour permettre configuration dynamique)
FILTER_ENABLED="${FILTER_ENABLED:-false}"
EXCLUDE_PATTERNS="${EXCLUDE_PATTERNS:-}"
INCLUDE_PATTERNS="${INCLUDE_PATTERNS:-}"
EXCLUDE_FILE="${EXCLUDE_FILE:-}"
INCLUDE_FILE="${INCLUDE_FILE:-}"

# Tableaux pour stocker les patterns (mutables par design)
declare -a EXCLUDE_PATTERNS_ARRAY
declare -a INCLUDE_PATTERNS_ARRAY

# Fonction pour obtenir les informations du module
get_filters_module_info() {
    echo "Module: $FILTERS_MODULE_NAME"
    echo "Version: $FILTERS_VERSION"
    echo "Patterns: ${#EXCLUDE_PATTERNS_ARRAY[@]} exclusion, ${#INCLUDE_PATTERNS_ARRAY[@]} inclusion"
}

# Initialise le module de filtrage
filters_init() {
    # Vérifier les dépendances externes
    if ! command -v jq &> /dev/null; then
        log_error "jq n'est pas installé. Le module de filtrage nécessite jq."
        return 1
    fi
    
    if ! command -v base64 &> /dev/null; then
        log_error "base64 n'est pas installé. Le module de filtrage nécessite base64."
        return 1
    fi
    
    # Vider les tableaux
    EXCLUDE_PATTERNS_ARRAY=()
    INCLUDE_PATTERNS_ARRAY=()
    
    # Charger les patterns d'exclusion
    if [ -n "$EXCLUDE_PATTERNS" ]; then
        IFS=',' read -ra patterns <<< "$EXCLUDE_PATTERNS"
        for pattern in "${patterns[@]}"; do
            EXCLUDE_PATTERNS_ARRAY+=("$pattern")
        done
    fi
    
    # Charger les patterns d'inclusion
    if [ -n "$INCLUDE_PATTERNS" ]; then
        IFS=',' read -ra patterns <<< "$INCLUDE_PATTERNS"
        for pattern in "${patterns[@]}"; do
            INCLUDE_PATTERNS_ARRAY+=("$pattern")
        done
    fi
    
    # Charger depuis les fichiers si spécifiés
    if [ -n "$EXCLUDE_FILE" ] && [ -f "$EXCLUDE_FILE" ]; then
        while IFS= read -r pattern; do
            [ -n "$pattern" ] && EXCLUDE_PATTERNS_ARRAY+=("$pattern")
        done < "$EXCLUDE_FILE"
    fi
    
    if [ -n "$INCLUDE_FILE" ] && [ -f "$INCLUDE_FILE" ]; then
        while IFS= read -r pattern; do
            [ -n "$pattern" ] && INCLUDE_PATTERNS_ARRAY+=("$pattern")
        done < "$INCLUDE_FILE"
    fi
    
    log_debug "Module de filtrage initialisé"
    log_debug "Patterns d'exclusion: ${#EXCLUDE_PATTERNS_ARRAY[@]}"
    log_debug "Patterns d'inclusion: ${#INCLUDE_PATTERNS_ARRAY[@]}"
}

# Vérifie si un dépôt doit être traité
filters_should_process() {
    local repo_name="$1"
    local repo_full_name="$2"
    
    # Si le filtrage est désactivé, traiter tous les dépôts
    if [ "$FILTER_ENABLED" != "true" ]; then
        return 0
    fi
    
    # Vérifier les patterns d'inclusion d'abord
    if [ ${#INCLUDE_PATTERNS_ARRAY[@]} -gt 0 ]; then
        local included=false
        
        for pattern in "${INCLUDE_PATTERNS_ARRAY[@]}"; do
            if filters_match_pattern "$repo_name" "$pattern" || \
               filters_match_pattern "$repo_full_name" "$pattern"; then
                included=true
                break
            fi
        done
        
        if [ "$included" = false ]; then
            log_debug "Dépôt exclu par patterns d'inclusion: $repo_name"
            return 1
        fi
    fi
    
    # Vérifier les patterns d'exclusion
    for pattern in "${EXCLUDE_PATTERNS_ARRAY[@]}"; do
        if filters_match_pattern "$repo_name" "$pattern" || \
           filters_match_pattern "$repo_full_name" "$pattern"; then
            log_debug "Dépôt exclu par pattern: $repo_name (pattern: $pattern)"
            return 1
        fi
    done
    
    return 0
}

# Vérifie si un nom correspond à un pattern
filters_match_pattern() {
    local name="$1"
    local pattern="$2"
    
    # Limiter la longueur du pattern pour prévenir les attaques
    if [ ${#pattern} -gt 100 ]; then
        log_debug "Pattern trop long, rejeté: ${pattern:0:50}..."
        return 1
    fi
    
    # Pattern exact
    if [ "$name" = "$pattern" ]; then
        return 0
    fi
    
    # Pattern glob (avec *)
    if [[ "$pattern" == *"*"* ]]; then
        # shellcheck disable=SC2053
        # Pattern sans quotes nécessaire pour activer le glob matching
        if [[ "$name" == $pattern ]]; then
            return 0
        fi
    fi
    
    # Pattern regex (commence par ^ et finit par $)
    if [[ "$pattern" =~ ^\^.*\$$ ]]; then
        # Protection ReDoS avec timeout (seulement si pattern suspect)
        if [[ "$pattern" =~ (\)\+|\+\+|\.\.+).* ]]; then
            # Pattern potentiellement dangereux : utiliser timeout
            if timeout 0.1 bash -c "[[ \"test\" =~ $pattern ]]" 2>/dev/null; then
                if [[ "$name" =~ $pattern ]]; then
                    return 0
                fi
            else
                log_debug "Pattern regex complexe ou invalide (possible ReDoS): ${pattern:0:50}..."
                return 1
            fi
        else
            # Pattern simple : pas besoin de timeout
            if [[ "$name" =~ $pattern ]]; then
                return 0
            fi
        fi
    fi
    
    # Pattern regex simple
    if [[ "$pattern" =~ ^[^a-zA-Z0-9_-] ]]; then
        # Protection ReDoS avec timeout (seulement si pattern suspect)
        if [[ "$pattern" =~ (\)\+|\+\+|\.\.+).* ]]; then
            # Pattern potentiellement dangereux : utiliser timeout
            if timeout 0.1 bash -c "[[ \"test\" =~ $pattern ]]" 2>/dev/null; then
                if [[ "$name" =~ $pattern ]]; then
                    return 0
                fi
            else
                log_debug "Pattern regex complexe ou invalide (possible ReDoS): ${pattern:0:50}..."
                return 1
            fi
        else
            # Pattern simple : pas besoin de timeout
            if [[ "$name" =~ $pattern ]]; then
                return 0
            fi
        fi
    fi
    
    return 1
}

# Filtre une liste de dépôts
filters_filter_repos() {
    local repos_json="$1"
    local filtered_repos="[]"
    
    if [ "$FILTER_ENABLED" != "true" ]; then
        echo "$repos_json"
        return 0
    fi
    
    # Logger vers stderr pour ne pas polluer stdout
    log_info "Filtrage des dépôts..." >&2
    
    local total_count
    total_count=$(echo "$repos_json" | jq 'length')
    local filtered_count=0
    
    # Traiter chaque dépôt (correction bug subshell)
    # Utilisation de process substitution au lieu de pipe pour éviter le subshell
    while IFS= read -r repo_b64; do
        local repo
        repo=$(echo "$repo_b64" | base64 -d)
        
        local repo_name
        repo_name=$(echo "$repo" | jq -r '.name')
        local repo_full_name
        repo_full_name=$(echo "$repo" | jq -r '.full_name')
        
        if filters_should_process "$repo_name" "$repo_full_name"; then
            filtered_repos=$(echo "$filtered_repos" | jq ". + [$repo]")
            filtered_count=$((filtered_count + 1))
        fi
    done < <(echo "$repos_json" | jq -r '.[] | @base64')
    
    # Logger vers stderr pour ne pas polluer stdout
    log_success "Filtrage terminé: $filtered_count/$total_count dépôts conservés" >&2
    
    echo "$filtered_repos"
    return 0
}

# Affiche un résumé des patterns de filtrage
filters_show_summary() {
    if [ "$FILTER_ENABLED" != "true" ]; then
        log_info "Filtrage désactivé"
        return 0
    fi
    
    log_info "=== Résumé du Filtrage ==="
    
    if [ ${#EXCLUDE_PATTERNS_ARRAY[@]} -gt 0 ]; then
        log_info "Patterns d'exclusion:"
        for pattern in "${EXCLUDE_PATTERNS_ARRAY[@]}"; do
            log_info "  - $pattern"
        done
    fi
    
    if [ ${#INCLUDE_PATTERNS_ARRAY[@]} -gt 0 ]; then
        log_info "Patterns d'inclusion:"
        for pattern in "${INCLUDE_PATTERNS_ARRAY[@]}"; do
            log_info "  - $pattern"
        done
    fi
    
    if [ -n "$EXCLUDE_FILE" ] && [ -f "$EXCLUDE_FILE" ]; then
        log_info "Fichier d'exclusion: $EXCLUDE_FILE"
    fi
    
    if [ -n "$INCLUDE_FILE" ] && [ -f "$INCLUDE_FILE" ]; then
        log_info "Fichier d'inclusion: $INCLUDE_FILE"
    fi
    
    log_info "========================"
}

# Valide les patterns de filtrage
filters_validate_patterns() {
    local valid=true
    
    # Vérifier les patterns d'exclusion
    for pattern in "${EXCLUDE_PATTERNS_ARRAY[@]}"; do
        if ! filters_validate_pattern "$pattern"; then
            log_error "Pattern d'exclusion invalide: $pattern"
            valid=false
        fi
    done
    
    # Vérifier les patterns d'inclusion
    for pattern in "${INCLUDE_PATTERNS_ARRAY[@]}"; do
        if ! filters_validate_pattern "$pattern"; then
            log_error "Pattern d'inclusion invalide: $pattern"
            valid=false
        fi
    done
    
    if [ "$valid" = false ]; then
        return 1
    fi
    
    return 0
}

# Valide un pattern individuel
filters_validate_pattern() {
    local pattern="$1"
    
    if [ -z "$pattern" ]; then
        return 1
    fi
    
    # Limiter la longueur du pattern
    if [ ${#pattern} -gt 100 ]; then
        return 1
    fi
    
    # Vérifier si c'est un pattern regex valide
    if [[ "$pattern" =~ ^\^.*\$$ ]]; then
        # Test simple sans timeout pour validation
        if [[ "test" =~ $pattern ]] 2>/dev/null; then
            : # Pattern valide
        else
            return 1
        fi
    fi
    
    # Vérifier si c'est un pattern glob valide
    if [[ "$pattern" == *"*"* ]]; then
        # Glob patterns sont toujours valides (matching dynamique)
        : # Pattern valide
    fi
    
    return 0
}

# Fonction principale d'initialisation du module de filtrage
filters_setup() {
    if ! filters_init; then
        log_error "Échec de l'initialisation du module de filtrage"
        return 1
    fi
    
    if [ "$FILTER_ENABLED" = "true" ]; then
        if ! filters_validate_patterns; then
            log_error "Validation des patterns de filtrage échouée"
            return 1
        fi
        
        filters_show_summary
    fi
    
    log_success "Module de filtrage initialisé avec succès"
    return 0
}

# Statistiques de filtrage
get_filter_stats() {
    echo "Filter Statistics:"
    echo "  Enabled: ${FILTER_ENABLED:-false}"
    echo "  Include patterns: ${FILTER_INCLUDE_PATTERNS:-0}"
    echo "  Exclude patterns: ${FILTER_EXCLUDE_PATTERNS:-0}"
}
