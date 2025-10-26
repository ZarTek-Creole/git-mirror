#!/bin/bash

# Configuration de sécurité Bash
set -euo pipefail

# lib/incremental/incremental.sh - Module de mode incrémental
# Gère le traitement uniquement des dépôts modifiés

# Variables de configuration
INCREMENTAL_ENABLED="${INCREMENTAL_ENABLED:-false}"
INCREMENTAL_CACHE_DIR="${INCREMENTAL_CACHE_DIR:-.git-mirror-cache/incremental}"
INCREMENTAL_LAST_SYNC_FILE="${INCREMENTAL_LAST_SYNC_FILE:-$INCREMENTAL_CACHE_DIR/last-sync}"

# Initialise le module incrémental
incremental_init() {
    # Créer le répertoire de cache incrémental
    mkdir -p "$INCREMENTAL_CACHE_DIR"
    
    log_debug "Module incrémental initialisé"
    log_debug "Cache incrémental: $INCREMENTAL_CACHE_DIR"
}

# Obtient la date de la dernière synchronisation
incremental_get_last_sync() {
    if [ ! -f "$INCREMENTAL_LAST_SYNC_FILE" ]; then
        log_debug "Aucune date de synchronisation précédente trouvée"
        echo ""
        return 0
    fi
    
    local last_sync
    last_sync=$(cat "$INCREMENTAL_LAST_SYNC_FILE" 2>/dev/null)
    
    if [ -n "$last_sync" ]; then
        log_debug "Dernière synchronisation: $last_sync"
        echo "$last_sync"
    else
        echo ""
    fi
    
    return 0
}

# Met à jour la date de la dernière synchronisation
incremental_update_timestamp() {
    local timestamp
    timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    
    echo "$timestamp" > "$INCREMENTAL_LAST_SYNC_FILE"
    log_debug "Timestamp de synchronisation mis à jour: $timestamp"
}

# Filtre les dépôts par date de dernière modification
incremental_filter_updated() {
    local repos_json="$1"
    local last_sync="$2"
    
    if [ "$INCREMENTAL_ENABLED" != "true" ]; then
        echo "$repos_json"
        return 0
    fi
    
    if [ -z "$last_sync" ]; then
        log_info "Mode incrémental activé mais aucune date de synchronisation précédente, traitement de tous les dépôts"
        echo "$repos_json"
        return 0
    fi
    
    log_info "Filtrage incrémental des dépôts modifiés depuis: $last_sync"
    
    # Convertir la date de synchronisation en timestamp Unix
    local last_sync_timestamp
    if ! last_sync_timestamp=$(date -d "$last_sync" +%s 2>/dev/null); then
        log_warning "Impossible de parser la date de synchronisation, traitement de tous les dépôts"
        echo "$repos_json"
        return 0
    fi
    
    local filtered_repos="[]"
    local total_count
    total_count=$(echo "$repos_json" | jq 'length')
    local updated_count=0
    
    # Traiter chaque dépôt
    echo "$repos_json" | jq -r '.[] | @base64' | while read -r repo_b64; do
        local repo
        repo=$(echo "$repo_b64" | base64 -d)
        
        local repo_name
        repo_name=$(echo "$repo" | jq -r '.name')
        local pushed_at
        pushed_at=$(echo "$repo" | jq -r '.pushed_at')
        
        # Convertir la date de push en timestamp Unix
        local pushed_timestamp
        if pushed_timestamp=$(date -d "$pushed_at" +%s 2>/dev/null) && [ "$pushed_timestamp" -gt "$last_sync_timestamp" ]; then
            filtered_repos=$(echo "$filtered_repos" | jq ". + [$repo]")
            updated_count=$((updated_count + 1))
            log_debug "Dépôt modifié: $repo_name (pushed_at: $pushed_at)"
        fi
    done
    
    log_success "Filtrage incrémental terminé: $updated_count/$total_count dépôts modifiés"
    
    echo "$filtered_repos"
    return 0
}

# Vérifie si un dépôt a été modifié depuis la dernière synchronisation
incremental_is_repo_updated() {
    local repo_name="$1"
    local pushed_at="$2"
    local last_sync="$3"
    
    if [ "$INCREMENTAL_ENABLED" != "true" ] || [ -z "$last_sync" ]; then
        return 0  # Traiter tous les dépôts si le mode incrémental est désactivé
    fi
    
    # Convertir les dates en timestamps Unix
    local pushed_timestamp
    pushed_timestamp=$(date -d "$pushed_at" +%s 2>/dev/null)
    
    local last_sync_timestamp
    if ! last_sync_timestamp=$(date -d "$last_sync" +%s 2>/dev/null) || [ -z "$pushed_timestamp" ] || [ -z "$last_sync_timestamp" ]; then
        log_warning "Impossible de comparer les dates pour $repo_name, traitement du dépôt"
        return 0
    fi
    
    if [ "$pushed_timestamp" -gt "$last_sync_timestamp" ]; then
        return 0  # Dépôt modifié
    else
        return 1  # Dépôt non modifié
    fi
}

# Obtient les statistiques du mode incrémental
incremental_get_stats() {
    local total_repos="$1"
    local processed_repos="$2"
    local last_sync="$3"
    
    if [ "$INCREMENTAL_ENABLED" != "true" ]; then
        echo "Mode incrémental désactivé"
        return 0
    fi
    
    local stats="=== Statistiques Mode Incrémental ==="
    stats+="\nDernière synchronisation: $last_sync"
    stats+="\nTotal dépôts: $total_repos"
    stats+="\nDépôts traités: $processed_repos"
    stats+="\nDépôts ignorés: $((total_repos - processed_repos))"
    stats+="\nTaux de traitement: $((processed_repos * 100 / total_repos))%"
    stats+="\n========================================"
    
    echo -e "$stats"
}

# Nettoie le cache incrémental
incremental_cleanup() {
    if [ -d "$INCREMENTAL_CACHE_DIR" ]; then
        rm -rf "$INCREMENTAL_CACHE_DIR"
        log_debug "Cache incrémental nettoyé"
    fi
}

# Affiche un résumé du mode incrémental
incremental_show_summary() {
    if [ "$INCREMENTAL_ENABLED" != "true" ]; then
        log_info "Mode incrémental désactivé"
        return 0
    fi
    
    local last_sync
    last_sync=$(incremental_get_last_sync)
    
    log_info "=== Résumé Mode Incrémental ==="
    log_info "Mode incrémental: Activé"
    
    if [ -n "$last_sync" ]; then
        log_info "Dernière synchronisation: $last_sync"
    else
        log_info "Première synchronisation (tous les dépôts seront traités)"
    fi
    
    log_info "Cache: $INCREMENTAL_CACHE_DIR"
    log_info "==============================="
}

# Fonction principale d'initialisation du module incrémental
incremental_setup() {
    if ! incremental_init; then
        log_error "Échec de l'initialisation du module incrémental"
        return 1
    fi
    
    if [ "$INCREMENTAL_ENABLED" = "true" ]; then
        incremental_show_summary
        log_success "Module incrémental initialisé avec succès"
    else
        log_debug "Module incrémental désactivé"
    fi
    
    return 0
}
