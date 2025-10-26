#!/bin/bash
# lib/filters/filters.sh - Module de filtrage des dépôts
# Gère l'exclusion et l'inclusion de dépôts par patterns

# Variables de configuration
FILTER_ENABLED="${FILTER_ENABLED:-false}"
EXCLUDE_PATTERNS="${EXCLUDE_PATTERNS:-}"
INCLUDE_PATTERNS="${INCLUDE_PATTERNS:-}"
EXCLUDE_FILE="${EXCLUDE_FILE:-}"
INCLUDE_FILE="${INCLUDE_FILE:-}"

# Tableaux pour stocker les patterns
declare -a EXCLUDE_PATTERNS_ARRAY
declare -a INCLUDE_PATTERNS_ARRAY

# Initialise le module de filtrage
filters_init() {
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
    
    # Pattern exact
    if [ "$name" = "$pattern" ]; then
        return 0
    fi
    
    # Pattern glob (avec *)
    if [[ "$pattern" == *"*"* ]]; then
        if [[ "$name" == $pattern ]]; then
            return 0
        fi
    fi
    
    # Pattern regex (commence par ^ et finit par $)
    if [[ "$pattern" =~ ^\^.*\$$ ]]; then
        if [[ "$name" =~ $pattern ]]; then
            return 0
        fi
    fi
    
    # Pattern regex simple
    if [[ "$pattern" =~ ^[^a-zA-Z0-9_-] ]]; then
        if [[ "$name" =~ $pattern ]]; then
            return 0
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
    
    log_info "Filtrage des dépôts..."
    
    local total_count
    total_count=$(echo "$repos_json" | jq 'length')
    local filtered_count=0
    
    # Traiter chaque dépôt
    echo "$repos_json" | jq -r '.[] | @base64' | while read -r repo_b64; do
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
    done
    
    log_success "Filtrage terminé: $filtered_count/$total_count dépôts conservés"
    
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
    
    # Vérifier si c'est un pattern regex valide
    if [[ "$pattern" =~ ^\^.*\$$ ]]; then
        if ! [[ "test" =~ $pattern ]]; then
            return 1
        fi
    fi
    
    # Vérifier si c'est un pattern glob valide
    if [[ "$pattern" == *"*"* ]]; then
        if ! [[ "test" == $pattern ]]; then
            return 1
        fi
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
