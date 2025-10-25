#!/bin/bash
# Module: Repository Filtering
# Description: Filtrage et exclusion de dépôts par patterns
# Pattern: Strategy + Chain of Responsibility + Factory
# Author: ZarTek-Creole
# Date: 2025-10-25

# Configuration de sécurité
set -euo pipefail

# Vérifier si le module est déjà chargé
if [ "${FILTER_MODULE_LOADED:-false}" = "true" ]; then
    return 0
fi

# Variables readonly pour la sécurité
readonly FILTER_VERSION="1.0.0"
readonly FILTER_MODULE_NAME="repository_filtering"
readonly FILTER_MODULE_LOADED="true"

# Export des métadonnées du module pour documentation
export FILTER_VERSION FILTER_MODULE_NAME

# Configuration des filtres
readonly DEFAULT_FILTER_FILE=".git-mirror-filters"
readonly MAX_PATTERNS=100

# Variables globales du module
FILTER_ENABLED=false
EXCLUDE_PATTERNS=()
INCLUDE_PATTERNS=()
EXCLUDE_FILE=""
INCLUDE_FILE=""
FILTER_MODE="exclude"  # exclude, include, both

# Interface publique du module Filter (Facade Pattern)
init_filter() {
    local enabled="${1:-false}"
    local exclude_patterns="${2:-}"
    local include_patterns="${3:-}"
    local exclude_file="${4:-}"
    local include_file="${5:-}"
    
    FILTER_ENABLED="$enabled"
    
    if [ "$FILTER_ENABLED" = true ]; then
        _load_filter_patterns "$exclude_patterns" "$include_patterns" "$exclude_file" "$include_file"
        _validate_filter_patterns
        log_success "Filtrage activé avec ${#EXCLUDE_PATTERNS[@]} patterns d'exclusion et ${#INCLUDE_PATTERNS[@]} patterns d'inclusion"
    else
        log_debug "Filtrage désactivé"
    fi
}

# Charger les patterns de filtrage
_load_filter_patterns() {
    local exclude_patterns="$1"
    local include_patterns="$2"
    local exclude_file="$3"
    local include_file="$4"
    
    # Charger les patterns d'exclusion
    if [ -n "$exclude_patterns" ]; then
        IFS=',' read -ra patterns <<< "$exclude_patterns"
        for pattern in "${patterns[@]}"; do
            EXCLUDE_PATTERNS+=("$pattern")
        done
    fi
    
    if [ -n "$exclude_file" ] && [ -f "$exclude_file" ]; then
        EXCLUDE_FILE="$exclude_file"
        while IFS= read -r pattern; do
            if [ -n "$pattern" ] && [[ ! "$pattern" =~ ^# ]]; then
                EXCLUDE_PATTERNS+=("$pattern")
            fi
        done < "$exclude_file"
    fi
    
    # Charger les patterns d'inclusion
    if [ -n "$include_patterns" ]; then
        IFS=',' read -ra patterns <<< "$include_patterns"
        for pattern in "${patterns[@]}"; do
            INCLUDE_PATTERNS+=("$pattern")
        done
    fi
    
    if [ -n "$include_file" ] && [ -f "$include_file" ]; then
        INCLUDE_FILE="$include_file"
        while IFS= read -r pattern; do
            if [ -n "$pattern" ] && [[ ! "$pattern" =~ ^# ]]; then
                INCLUDE_PATTERNS+=("$pattern")
            fi
        done < "$include_file"
    fi
    
    # Déterminer le mode de filtrage
    if [ ${#EXCLUDE_PATTERNS[@]} -gt 0 ] && [ ${#INCLUDE_PATTERNS[@]} -gt 0 ]; then
        FILTER_MODE="both"
    elif [ ${#INCLUDE_PATTERNS[@]} -gt 0 ]; then
        FILTER_MODE="include"
    else
        FILTER_MODE="exclude"
    fi
}

# Valider les patterns de filtrage
_validate_filter_patterns() {
    local total_patterns
    total_patterns=$((${#EXCLUDE_PATTERNS[@]} + ${#INCLUDE_PATTERNS[@]}))
    
    if [ $total_patterns -gt "$MAX_PATTERNS" ]; then
        log_warning "Nombre de patterns élevé: $total_patterns (max recommandé: $MAX_PATTERNS)"
    fi
    
    # Valider chaque pattern
    for pattern in "${EXCLUDE_PATTERNS[@]}"; do
        _validate_single_pattern "$pattern" "exclusion"
    done
    
    for pattern in "${INCLUDE_PATTERNS[@]}"; do
        _validate_single_pattern "$pattern" "inclusion"
    done
}

# Valider un pattern individuel
_validate_single_pattern() {
    local pattern="$1"
    local type="$2"
    
    # Vérifier la longueur
    if [ ${#pattern} -gt 255 ]; then
        log_warning "Pattern $type trop long (max 255 caractères): $pattern"
        return 1
    fi
    
    # Vérifier les caractères dangereux
    if echo "$pattern" | grep -q '[<>"'"'"'|&$`]'; then
        log_warning "Pattern $type contient des caractères potentiellement dangereux: $pattern"
        return 1
    fi
    
    return 0
}

# Vérifier si un dépôt doit être traité
should_process_repo() {
    local repo_name="$1"
    local repo_url="$2"
    
    if [ "$FILTER_ENABLED" = false ]; then
        return 0
    fi
    
    # Mode inclusion uniquement
    if [ "$FILTER_MODE" = "include" ]; then
        if _matches_patterns "$repo_name" "${INCLUDE_PATTERNS[@]}"; then
            return 0
        else
            log_debug "Dépôt exclu (non inclus): $repo_name"
            return 1
        fi
    fi
    
    # Mode exclusion uniquement
    if [ "$FILTER_MODE" = "exclude" ]; then
        if _matches_patterns "$repo_name" "${EXCLUDE_PATTERNS[@]}"; then
            log_debug "Dépôt exclu par pattern: $repo_name"
            return 1
        else
            return 0
        fi
    fi
    
    # Mode mixte (inclusion + exclusion)
    if [ "$FILTER_MODE" = "both" ]; then
        # D'abord vérifier l'inclusion
        if ! _matches_patterns "$repo_name" "${INCLUDE_PATTERNS[@]}"; then
            log_debug "Dépôt exclu (non inclus): $repo_name"
            return 1
        fi
        
        # Ensuite vérifier l'exclusion
        if _matches_patterns "$repo_name" "${EXCLUDE_PATTERNS[@]}"; then
            log_debug "Dépôt exclu par pattern: $repo_name"
            return 1
        fi
        
        return 0
    fi
    
    # Par défaut, traiter le dépôt
    return 0
}

# Vérifier si un nom correspond à des patterns
_matches_patterns() {
    local name="$1"
    shift
    local patterns=("$@")
    
    for pattern in "${patterns[@]}"; do
        if _matches_single_pattern "$name" "$pattern"; then
            return 0
        fi
    done
    
    return 1
}

# Vérifier si un nom correspond à un pattern
_matches_single_pattern() {
    local name="$1"
    local pattern="$2"
    
    # Pattern exact
    if [ "$name" = "$pattern" ]; then
        return 0
    fi
    
    # Pattern glob
    if [[ "$name" == "$pattern" ]]; then
        return 0
    fi
    
    # Pattern regex (si commence par ^ et finit par $)
    if [[ "$pattern" =~ ^\^.*\$$ ]]; then
        if [[ "$name" =~ $pattern ]]; then
            return 0
        fi
    fi
    
    # Pattern contient
    if [[ "$name" == *"$pattern"* ]]; then
        return 0
    fi
    
    return 1
}

# Filtrer une liste de dépôts
filter_repo_list() {
    local repos_json="$1"
    local filtered_repos=""
    local total_count=0
    local filtered_count=0
    
    if [ "$FILTER_ENABLED" = false ]; then
        echo "$repos_json"
        return 0
    fi
    
    log_info "Filtrage de la liste des dépôts..."
    
    # Parser le JSON et filtrer
    while IFS= read -r repo_info; do
        if [ -n "$repo_info" ] && [ "$repo_info" != "null" ]; then
            local repo_name
            local repo_url
            
            repo_name=$(echo "$repo_info" | jq -r '.name' 2>/dev/null || echo "")
            repo_url=$(echo "$repo_info" | jq -r '.clone_url' 2>/dev/null || echo "")
            
            total_count=$((total_count + 1))
            
            if should_process_repo "$repo_name" "$repo_url"; then
                filtered_repos="$filtered_repos
$repo_info"
                filtered_count=$((filtered_count + 1))
            fi
        fi
    done <<< "$repos_json"
    
    log_info "Filtrage terminé: $filtered_count/$total_count dépôts conservés"
    
    # Retourner la liste filtrée
    echo "$filtered_repos" | sed '/^$/d'
}

# Créer un fichier de filtres par défaut
create_default_filter_file() {
    local filter_file="${1:-$DEFAULT_FILTER_FILE}"
    
    cat > "$filter_file" << 'EOF'
# Fichier de filtres Git Mirror
# Format: un pattern par ligne, commentaires avec #
# Types de patterns supportés:
# - Exact: nom-exact
# - Glob: test-*, *-backup, *-old
# - Regex: ^(test|demo)-.*$
# - Contient: backup

# Exemples de patterns d'exclusion
test-*
*-test
*-backup
*-old
*-deprecated
demo-*
example-*

# Exemples de patterns d'inclusion (décommentez si nécessaire)
# main-*
# production-*
# stable-*
EOF
    
    log_info "Fichier de filtres par défaut créé: $filter_file"
}

# Ajouter un pattern d'exclusion
add_exclude_pattern() {
    local pattern="$1"
    local filter_file="${2:-$DEFAULT_FILTER_FILE}"
    
    if [ ! -f "$filter_file" ]; then
        create_default_filter_file "$filter_file"
    fi
    
    # Vérifier si le pattern existe déjà
    if grep -Fxq "$pattern" "$filter_file" 2>/dev/null; then
        log_warning "Pattern d'exclusion déjà présent: $pattern"
        return 1
    fi
    
    # Ajouter le pattern
    echo "$pattern" >> "$filter_file"
    log_success "Pattern d'exclusion ajouté: $pattern"
    
    return 0
}

# Ajouter un pattern d'inclusion
add_include_pattern() {
    local pattern="$1"
    local filter_file="${2:-$DEFAULT_FILTER_FILE}"
    
    if [ ! -f "$filter_file" ]; then
        create_default_filter_file "$filter_file"
    fi
    
    # Vérifier si le pattern existe déjà
    if grep -Fxq "$pattern" "$filter_file" 2>/dev/null; then
        log_warning "Pattern d'inclusion déjà présent: $pattern"
        return 1
    fi
    
    # Ajouter le pattern avec un préfixe pour le distinguer
    echo "#include: $pattern" >> "$filter_file"
    log_success "Pattern d'inclusion ajouté: $pattern"
    
    return 0
}

# Supprimer un pattern
remove_pattern() {
    local pattern="$1"
    local filter_file="${2:-$DEFAULT_FILTER_FILE}"
    
    if [ ! -f "$filter_file" ]; then
        log_warning "Fichier de filtres inexistant: $filter_file"
        return 1
    fi
    
    # Supprimer le pattern
    sed -i "/^$pattern$/d" "$filter_file"
    sed -i "/^#include: $pattern$/d" "$filter_file"
    
    log_success "Pattern supprimé: $pattern"
    return 0
}

# Lister les patterns actifs
list_patterns() {
    echo "Patterns de filtrage actifs:"
    echo ""
    
    if [ ${#EXCLUDE_PATTERNS[@]} -gt 0 ]; then
        echo "Exclusion:"
        for pattern in "${EXCLUDE_PATTERNS[@]}"; do
            echo "  - $pattern"
        done
        echo ""
    fi
    
    if [ ${#INCLUDE_PATTERNS[@]} -gt 0 ]; then
        echo "Inclusion:"
        for pattern in "${INCLUDE_PATTERNS[@]}"; do
            echo "  - $pattern"
        done
        echo ""
    fi
    
    echo "Mode: $FILTER_MODE"
    echo "Total patterns: $((${#EXCLUDE_PATTERNS[@]} + ${#INCLUDE_PATTERNS[@]}))"
}

# Tester un pattern sur un nom de dépôt
test_pattern() {
    local repo_name="$1"
    local pattern="$2"
    
    echo "Test du pattern '$pattern' sur '$repo_name':"
    
    if _matches_single_pattern "$repo_name" "$pattern"; then
        echo "  ✅ Correspondance trouvée"
        return 0
    else
        echo "  ❌ Aucune correspondance"
        return 1
    fi
}

# Obtenir les statistiques de filtrage
get_filter_stats() {
    echo "Repository Filtering Statistics:"
    echo "  Filter enabled: $FILTER_ENABLED"
    echo "  Filter mode: $FILTER_MODE"
    echo "  Exclude patterns: ${#EXCLUDE_PATTERNS[@]}"
    echo "  Include patterns: ${#INCLUDE_PATTERNS[@]}"
    echo "  Total patterns: $((${#EXCLUDE_PATTERNS[@]} + ${#INCLUDE_PATTERNS[@]}))"
    
    if [ -n "$EXCLUDE_FILE" ]; then
        echo "  Exclude file: $EXCLUDE_FILE"
    fi
    
    if [ -n "$INCLUDE_FILE" ]; then
        echo "  Include file: $INCLUDE_FILE"
    fi
}

# Export des fonctions publiques
export -f init_filter should_process_repo filter_repo_list create_default_filter_file add_exclude_pattern add_include_pattern remove_pattern list_patterns test_pattern get_filter_stats
