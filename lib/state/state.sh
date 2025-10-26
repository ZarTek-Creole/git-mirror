#!/bin/bash
# lib/state/state.sh - Module de gestion d'état et reprise
# Gère la sauvegarde et le chargement de l'état d'exécution

# Variables de configuration
STATE_FILE="${STATE_FILE:-.git-mirror-state.json}"
STATE_DIR="${STATE_DIR:-.git-mirror-state}"

# Structure de l'état
# {
#   "last_run": "2025-10-25T16:00:00Z",
#   "total_repos": 100,
#   "processed": 45,
#   "failed": ["repo1", "repo2"],
#   "success": ["repo3", "repo4"],
#   "interrupted": true,
#   "context": "users",
#   "username": "microsoft",
#   "destination": "./repositories"
# }

# Initialise le module d'état
state_init() {
    # Créer le répertoire d'état si nécessaire
    mkdir -p "$STATE_DIR"
    
    log_debug "Module d'état initialisé"
    log_debug "Fichier d'état: $STATE_FILE"
}

# Sauvegarde l'état actuel
state_save() {
    local context="$1"
    local username="$2"
    local destination="$3"
    local total_repos="$4"
    local processed="$5"
    local failed_repos="$6"
    local success_repos="$7"
    local interrupted="${8:-false}"
    
    local state_data
    state_data=$(cat <<EOF
{
  "last_run": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "total_repos": $total_repos,
  "processed": $processed,
  "failed": $(echo "$failed_repos" | jq -R 'split("\n") | map(select(. != ""))'),
  "success": $(echo "$success_repos" | jq -R 'split("\n") | map(select(. != ""))'),
  "interrupted": $interrupted,
  "context": "$context",
  "username": "$username",
  "destination": "$destination"
}
EOF
)
    
    echo "$state_data" > "$STATE_FILE"
    log_debug "État sauvegardé: $processed/$total_repos dépôts traités"
}

# Charge l'état précédent
state_load() {
    if [ ! -f "$STATE_FILE" ]; then
        log_debug "Aucun fichier d'état trouvé"
        return 1
    fi
    
    if ! jq empty "$STATE_FILE" 2>/dev/null; then
        log_warning "Fichier d'état corrompu, suppression"
        rm -f "$STATE_FILE"
        return 1
    fi
    
    log_debug "État chargé depuis: $STATE_FILE"
    return 0
}

# Détermine si une reprise est nécessaire
state_should_resume() {
    if [ ! -f "$STATE_FILE" ]; then
        return 1
    fi
    
    local interrupted
    interrupted=$(jq -r '.interrupted // false' "$STATE_FILE")
    
    if [ "$interrupted" = "true" ]; then
        return 0
    fi
    
    return 1
}

# Obtient les informations de l'état
state_get_info() {
    if [ ! -f "$STATE_FILE" ]; then
        return 1
    fi
    
    local context
    context=$(jq -r '.context // ""' "$STATE_FILE")
    local username
    username=$(jq -r '.username // ""' "$STATE_FILE")
    local destination
    destination=$(jq -r '.destination // ""' "$STATE_FILE")
    local total_repos
    total_repos=$(jq -r '.total_repos // 0' "$STATE_FILE")
    local processed
    processed=$(jq -r '.processed // 0' "$STATE_FILE")
    local failed_count
    failed_count=$(jq -r '.failed | length' "$STATE_FILE")
    local success_count
    success_count=$(jq -r '.success | length' "$STATE_FILE")
    
    echo "$context|$username|$destination|$total_repos|$processed|$failed_count|$success_count"
}

# Obtient la liste des dépôts déjà traités avec succès
state_get_processed() {
    if [ ! -f "$STATE_FILE" ]; then
        echo "[]"
        return 0
    fi
    
    jq -r '.success // []' "$STATE_FILE"
}

# Obtient la liste des dépôts en échec
state_get_failed() {
    if [ ! -f "$STATE_FILE" ]; then
        echo "[]"
        return 0
    fi
    
    jq -r '.failed // []' "$STATE_FILE"
}

# Ajoute un dépôt à la liste des succès
state_add_success() {
    local repo_name="$1"
    
    if [ ! -f "$STATE_FILE" ]; then
        return 1
    fi
    
    local temp_file
    temp_file=$(mktemp)
    
    jq --arg repo "$repo_name" '.success += [$repo]' "$STATE_FILE" > "$temp_file" && \
    mv "$temp_file" "$STATE_FILE"
    
    log_debug "Dépôt ajouté aux succès: $repo_name"
}

# Ajoute un dépôt à la liste des échecs
state_add_failed() {
    local repo_name="$1"
    
    if [ ! -f "$STATE_FILE" ]; then
        return 1
    fi
    
    local temp_file
    temp_file=$(mktemp)
    
    jq --arg repo "$repo_name" '.failed += [$repo]' "$STATE_FILE" > "$temp_file" && \
    mv "$temp_file" "$STATE_FILE"
    
    log_debug "Dépôt ajouté aux échecs: $repo_name"
}

# Met à jour le compteur de dépôts traités
state_update_processed() {
    local processed="$1"
    
    if [ ! -f "$STATE_FILE" ]; then
        return 1
    fi
    
    local temp_file
    temp_file=$(mktemp)
    
    jq --argjson processed "$processed" '.processed = $processed' "$STATE_FILE" > "$temp_file" && \
    mv "$temp_file" "$STATE_FILE"
    
    log_debug "Compteur de dépôts traités mis à jour: $processed"
}

# Marque l'état comme interrompu
state_mark_interrupted() {
    if [ ! -f "$STATE_FILE" ]; then
        return 1
    fi
    
    local temp_file
    temp_file=$(mktemp)
    
    jq '.interrupted = true' "$STATE_FILE" > "$temp_file" && \
    mv "$temp_file" "$STATE_FILE"
    
    log_debug "État marqué comme interrompu"
}

# Marque l'état comme terminé avec succès
state_mark_completed() {
    if [ ! -f "$STATE_FILE" ]; then
        return 1
    fi
    
    local temp_file
    temp_file=$(mktemp)
    
    jq '.interrupted = false' "$STATE_FILE" > "$temp_file" && \
    mv "$temp_file" "$STATE_FILE"
    
    log_debug "État marqué comme terminé avec succès"
}

# Nettoie l'état après succès
state_clean() {
    if [ -f "$STATE_FILE" ]; then
        rm -f "$STATE_FILE"
        log_debug "État nettoyé après succès"
    fi
}

# Affiche un résumé de l'état
state_show_summary() {
    if [ ! -f "$STATE_FILE" ]; then
        log_info "Aucun état précédent trouvé"
        return 0
    fi
    
    local info
    if ! info=$(state_get_info); then
        log_warning "Impossible de lire l'état précédent"
        return 1
    fi
    
    IFS='|' read -r context username destination total_repos processed failed_count success_count <<< "$info"
    
    log_info "=== État Précédent ==="
    log_info "Contexte: $context"
    log_info "Utilisateur: $username"
    log_info "Destination: $destination"
    log_info "Total dépôts: $total_repos"
    log_info "Traités: $processed"
    log_info "Succès: $success_count"
    log_info "Échecs: $failed_count"
    log_info "====================="
}

# Fonction principale d'initialisation du module d'état
state_setup() {
    if ! state_init; then
        log_error "Échec de l'initialisation du module d'état"
        return 1
    fi
    
    log_success "Module d'état initialisé avec succès"
    return 0
}
