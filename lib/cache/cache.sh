#!/bin/bash
# Module: Cache Management
# Description: Gestion du cache avec TTL et persistance
# Pattern: Strategy + Observer + Singleton
# Author: ZarTek-Creole
# Date: 2025-10-25

# Configuration de sécurité
set -euo pipefail

# Vérifier si le module est déjà chargé
if [ "${CACHE_MODULE_LOADED:-false}" = "true" ]; then
    return 0
fi

# Variables readonly pour la sécurité
readonly CACHE_VERSION="1.0.0"
readonly CACHE_MODULE_NAME="cache_management"
readonly CACHE_MODULE_LOADED="true"

# Configuration du cache
readonly DEFAULT_CACHE_TTL=3600  # 1 heure
readonly CACHE_CLEANUP_INTERVAL=86400  # 24 heures

# Variables globales du module
CACHE_DIR=""
CACHE_TTL="$DEFAULT_CACHE_TTL"
CACHE_ENABLED=true
CACHE_HITS=0
CACHE_MISSES=0

# Obtenir les informations du module cache
get_cache_module_info() {
    echo "Module: $CACHE_MODULE_NAME v$CACHE_VERSION"
    echo "Répertoire cache: $CACHE_DIR"
    echo "TTL par défaut: $CACHE_TTL secondes"
    echo "Intervalle de nettoyage: $CACHE_CLEANUP_INTERVAL secondes"
}

# Interface publique du module Cache (Facade Pattern)
init_cache() {
    local cache_dir="${1:-.git-mirror-cache}"
    local ttl="${2:-$DEFAULT_CACHE_TTL}"
    local enabled="${3:-true}"
    
    CACHE_DIR="$cache_dir"
    CACHE_TTL="$ttl"
    CACHE_ENABLED="$enabled"
    
    if [ "$CACHE_ENABLED" = true ]; then
        _create_cache_structure
        _cleanup_expired_cache
    fi
    
    log_debug "Cache initialisé - Répertoire: $CACHE_DIR, TTL: ${CACHE_TTL}s, Activé: $CACHE_ENABLED"
}

# Créer la structure du cache
_create_cache_structure() {
    mkdir -p "$CACHE_DIR/api" "$CACHE_DIR/metadata" "$CACHE_DIR/state" 2>/dev/null || true
}

# Obtenir une valeur du cache
cache_get() {
    local key="$1"
    
    if [ "$CACHE_ENABLED" = false ]; then
        CACHE_MISSES=$((CACHE_MISSES + 1))
        return 1
    fi
    
    local cache_file="$CACHE_DIR/metadata/$key.json"
    
    if [ ! -f "$cache_file" ]; then
        CACHE_MISSES=$((CACHE_MISSES + 1))
        return 1
    fi
    
    # Vérifier le TTL
    local cache_age
    cache_age=$(($(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || echo 0)))
    
    if [ $cache_age -gt "$CACHE_TTL" ]; then
        rm -f "$cache_file"
        CACHE_MISSES=$((CACHE_MISSES + 1))
        return 1
    fi
    
    CACHE_HITS=$((CACHE_HITS + 1))
    cat "$cache_file"
    return 0
}

# Stocker une valeur dans le cache
cache_set() {
    local key="$1"
    local data="$2"
    
    if [ "$CACHE_ENABLED" = false ]; then
        return 0
    fi
    
    local cache_file="$CACHE_DIR/metadata/$key.json"
    
    # Créer le répertoire si nécessaire
    mkdir -p "$(dirname "$cache_file")" 2>/dev/null || true
    
    # Stocker les données
    echo "$data" > "$cache_file" 2>/dev/null || {
        log_warning "Impossible d'écrire dans le cache: $cache_file"
        return 1
    }
    
    log_debug "Données mises en cache: $key"
    return 0
}

# Supprimer une clé du cache
cache_delete() {
    local key="$1"
    
    local cache_file="$CACHE_DIR/metadata/$key.json"
    rm -f "$cache_file" 2>/dev/null || true
    
    log_debug "Clé supprimée du cache: $key"
}

# Vérifier si une clé existe dans le cache
cache_exists() {
    local key="$1"
    
    if [ "$CACHE_ENABLED" = false ]; then
        return 1
    fi
    
    local cache_file="$CACHE_DIR/metadata/$key.json"
    
    if [ ! -f "$cache_file" ]; then
        return 1
    fi
    
    # Vérifier le TTL
    local cache_age
    cache_age=$(($(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || echo 0)))
    
    if [ $cache_age -gt "$CACHE_TTL" ]; then
        rm -f "$cache_file"
        return 1
    fi
    
    return 0
}

# Obtenir le nombre total de dépôts depuis le cache
cache_get_total_repos() {
    local context="$1"
    local username="$2"
    local cache_key="total_repos_${context}_${username}"
    
    cache_get "$cache_key"
}

# Stocker le nombre total de dépôts dans le cache
cache_set_total_repos() {
    local context="$1"
    local username="$2"
    local total="$3"
    local cache_key="total_repos_${context}_${username}"
    
    cache_set "$cache_key" "$total"
}

# Obtenir le timestamp de la dernière synchronisation
cache_get_last_sync() {
    local context="$1"
    local username="$2"
    local cache_file="$CACHE_DIR/last-sync-${context}-${username}.txt"
    
    if [ -f "$cache_file" ]; then
        cat "$cache_file"
    else
        echo "1970-01-01T00:00:00Z"  # Époque Unix par défaut
    fi
}

# Mettre à jour le timestamp de la dernière synchronisation
cache_set_last_sync() {
    local context="$1"
    local username="$2"
    local cache_file="$CACHE_DIR/last-sync-${context}-${username}.txt"
    
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    echo "$timestamp" > "$cache_file"
    
    if [ "$VERBOSE_LEVEL" -ge 2 ]; then
        log_debug "Timestamp de synchronisation mis à jour: $timestamp"
    fi
}

# Obtenir les données d'état depuis le cache
cache_get_state() {
    local state_file="$CACHE_DIR/state/current.json"
    
    if [ -f "$state_file" ]; then
        cat "$state_file"
    else
        echo "{}"
    fi
}

# Stocker les données d'état dans le cache
cache_set_state() {
    local state_data="$1"
    local state_file="$CACHE_DIR/state/current.json"
    
    # Créer le répertoire si nécessaire
    mkdir -p "$(dirname "$state_file")" 2>/dev/null || true
    
    echo "$state_data" > "$state_file" 2>/dev/null || {
        log_warning "Impossible d'écrire l'état dans le cache: $state_file"
        return 1
    }
}

# Nettoyer le cache expiré
_cleanup_expired_cache() {
    if [ ! -d "$CACHE_DIR/metadata" ]; then
        return 0
    fi
    
    local current_time
    current_time=$(date +%s)
    local cleaned_count=0
    
    # Nettoyer les fichiers de cache expirés
    find "$CACHE_DIR/metadata" -name "*.json" -type f | while read -r cache_file; do
        local file_age
        file_age=$((current_time - $(stat -c %Y "$cache_file" 2>/dev/null || echo 0)))
        
        if [ $file_age -gt "$CACHE_TTL" ]; then
            rm -f "$cache_file" 2>/dev/null || true
            cleaned_count=$((cleaned_count + 1))
        fi
    done
    
    if [ $cleaned_count -gt 0 ] && [ "$VERBOSE_LEVEL" -ge 2 ]; then
        log_debug "Cache nettoyé: $cleaned_count entrées expirées supprimées"
    fi
}

# Vider complètement le cache
cache_clear() {
    if [ -d "$CACHE_DIR" ]; then
        rm -rf "$CACHE_DIR" 2>/dev/null || true
        log_info "Cache vidé complètement"
    fi
    
    # Réinitialiser les compteurs
    CACHE_HITS=0
    CACHE_MISSES=0
}

# Obtenir les statistiques du cache
get_cache_stats() {
    local total_requests
    total_requests=$((CACHE_HITS + CACHE_MISSES))
    local hit_rate=0
    
    if [ $total_requests -gt 0 ]; then
        hit_rate=$((CACHE_HITS * 100 / total_requests))
    fi
    
    echo "Cache Statistics:"
    echo "  Cache directory: $CACHE_DIR"
    echo "  Cache enabled: $CACHE_ENABLED"
    echo "  Cache TTL: ${CACHE_TTL}s"
    echo "  Cache hits: $CACHE_HITS"
    echo "  Cache misses: $CACHE_MISSES"
    echo "  Hit rate: ${hit_rate}%"
    
    if [ -d "$CACHE_DIR/metadata" ]; then
        local cache_files_count
        cache_files_count=$(find "$CACHE_DIR/metadata" -name "*.json" -type f | wc -l)
        echo "  Cached entries: $cache_files_count"
    fi
}

# Vérifier l'intégrité du cache
cache_verify() {
    if [ ! -d "$CACHE_DIR" ]; then
        log_warning "Répertoire de cache inexistant: $CACHE_DIR"
        return 1
    fi
    
    local issues=0
    
    # Vérifier les permissions
    if [ ! -w "$CACHE_DIR" ]; then
        log_error "Permissions insuffisantes sur le répertoire de cache: $CACHE_DIR"
        issues=$((issues + 1))
    fi
    
    # Vérifier l'espace disque
    local available_space
    available_space=$(df "$CACHE_DIR" | awk 'NR==2 {print $4}')
    if [ "$available_space" -lt 100 ]; then  # Moins de 100KB
        log_warning "Espace disque faible pour le cache: ${available_space}KB"
        issues=$((issues + 1))
    fi
    
    if [ $issues -eq 0 ]; then
        log_success "Cache vérifié avec succès"
        return 0
    else
        log_error "Cache vérifié avec $issues problème(s)"
        return 1
    fi
}

# Fonction principale d'initialisation du module cache
cache_setup() {
    init_cache "${CACHE_DIR:-.git-mirror-cache}" "${CACHE_TTL:-3600}" true
    log_debug "Module cache initialisé"
    return 0
}

# Export des fonctions publiques
export -f init_cache cache_get cache_set cache_delete cache_exists cache_get_total_repos cache_set_total_repos cache_get_last_sync cache_set_last_sync cache_get_state cache_set_state cache_clear get_cache_stats cache_verify cache_setup
