#!/bin/bash

# Configuration de sécurité Bash
set -euo pipefail

# lib/api/github_api.sh - Module d'API GitHub
# Gère les appels API avec cache, rate limiting et pagination

# Variables de configuration
API_BASE_URL="https://api.github.com"
API_CACHE_DIR="${CACHE_DIR:-.git-mirror-cache}/api"
API_CACHE_TTL="${API_CACHE_TTL:-3600}"  # 1 heure par défaut

# Initialise le module API
api_init() {
    # Créer le répertoire de cache API
    mkdir -p "$API_CACHE_DIR"
    
    log_debug "Module API GitHub initialisé"
    log_debug "Cache API: $API_CACHE_DIR (TTL: ${API_CACHE_TTL}s)"
}

# Vérifie les limites de taux API restantes
api_check_rate_limit() {
    local headers
    headers=$(auth_get_headers "$GITHUB_AUTH_METHOD")
    
    local response
    if ! response=$(eval "curl -s $headers -H \"Accept: application/vnd.github.v3+json\" \"$API_BASE_URL/rate_limit\"" 2>/dev/null); then
        log_warning "Impossible de vérifier les limites de taux API"
        return 1
    fi
    
    local remaining
    remaining=$(echo "$response" | jq -r '.rate.remaining // 0')
    local limit
    limit=$(echo "$response" | jq -r '.rate.limit // 60')
    local reset_time
    reset_time=$(echo "$response" | jq -r '.rate.reset // 0')
    
    log_debug "Limite API: $remaining/$limit requêtes restantes"
    
    # Avertir si moins de 10% des requêtes restent
    if [ "$remaining" -lt $((limit / 10)) ]; then
        log_warning "Limite de taux API GitHub atteinte ($remaining/$limit requêtes restantes)"
        
        # Calculer le temps d'attente
        local current_time
        current_time=$(date +%s)
        local wait_time=$((reset_time - current_time))
        
        if [ "$wait_time" -gt 0 ]; then
            log_info "Attente de ${wait_time}s pour la réinitialisation..."
            sleep "$wait_time"
        fi
    fi
    
    return 0
}

# Attend si la limite de taux est atteinte
api_wait_rate_limit() {
    local headers
    headers=$(auth_get_headers "$GITHUB_AUTH_METHOD")
    
    local response
    if ! response=$(eval "curl -s $headers -H \"Accept: application/vnd.github.v3+json\" \"$API_BASE_URL/rate_limit\"" 2>/dev/null); then
        return 1
    fi
    
    local remaining
    remaining=$(echo "$response" | jq -r '.rate.remaining // 0')
    local reset_time
    reset_time=$(echo "$response" | jq -r '.rate.reset // 0')
    
    if [ "$remaining" -eq 0 ]; then
        local current_time
        current_time=$(date +%s)
        local wait_time=$((reset_time - current_time))
        
        if [ "$wait_time" -gt 0 ]; then
            log_info "Attente de ${wait_time}s pour la réinitialisation de la limite API..."
            sleep "$wait_time"
        fi
    fi
    
    return 0
}

# Génère une clé de cache pour une URL
api_cache_key() {
    local url="$1"
    echo "$url" | tr '/' '_' | tr ':' '_' | tr '?' '_' | tr '&' '_' | tr '=' '_'
}

# Vérifie si un cache est valide
api_cache_valid() {
    local cache_file="$1"
    local ttl="$2"
    
    if [ ! -f "$cache_file" ]; then
        return 1
    fi
    
    local file_age
    file_age=$(($(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || echo 0)))
    
    if [ "$file_age" -lt "$ttl" ]; then
        return 0
    fi
    
    return 1
}

# Récupère des données avec cache
api_fetch_with_cache() {
    local url="$1"
    local cache_key
    cache_key=$(api_cache_key "$url")
    local cache_file="$API_CACHE_DIR/$cache_key.json"
    
    # Vérifier le cache
    if api_cache_valid "$cache_file" "$API_CACHE_TTL"; then
        log_debug "Utilisation du cache pour: $url"
        cat "$cache_file"
        return 0
    fi
    
    # Vérifier les limites de taux
    if ! api_check_rate_limit; then
        log_warning "Limite de taux API atteinte, utilisation du cache expiré si disponible"
        if [ -f "$cache_file" ]; then
            cat "$cache_file"
            return 0
        fi
        return 1
    fi
    
    # Créer le répertoire de cache si nécessaire
    mkdir -p "$API_CACHE_DIR"
    
    # Faire l'appel API avec gestion des erreurs améliorée
    local headers
    headers=$(auth_get_headers "$GITHUB_AUTH_METHOD")
    
    local response
    local http_code
    # Capturer uniquement stdout (curl), pas stderr (pour éviter les messages DEBUG)
    response=$(eval "curl -s -w \"%{http_code}\" $headers -H \"Accept: application/vnd.github.v3+json\" \"$url\" 2>&1")
    http_code="${response: -3}"
    response="${response%???}"
    
    log_debug "Réponse HTTP: $http_code pour $url"
    log_debug "Headers utilisés: $headers"
    
    # Gérer les codes de réponse HTTP
    case "$http_code" in
        200)
            # Succès
            log_debug "Réponse API reçue avec succès (200)"
            ;;
        403)
            log_error "Accès refusé (403) - Limite de taux API GitHub atteinte"
            log_info "Utilisation d'un token GitHub recommandée pour éviter les limites"
            return 1
            ;;
        404)
            log_error "Ressource non trouvée (404) - Vérifiez le nom d'utilisateur/organisation"
            return 1
            ;;
        429)
            log_error "Trop de requêtes (429) - Limite de taux dépassée"
            api_wait_rate_limit
            return 1
            ;;
        *)
            log_error "Erreur HTTP $http_code pour $url"
            return 1
            ;;
    esac
    
    # Vérifier si la réponse est vide
    if [ -z "$response" ]; then
        log_error "Réponse vide de l'API GitHub"
        return 1
    fi
    
    # Vérifier si c'est un JSON valide
    if ! echo "$response" | jq . >/dev/null 2>&1; then
        log_error "Réponse JSON invalide de l'API GitHub"
        log_debug "Longueur de la réponse: ${#response} caractères"
        log_debug "Premiers 200 caractères: $(echo "$response" | head -c 200)"
        log_debug "Échec de la validation jq"
        return 1
    fi
    
    # Vérifier les erreurs dans la réponse JSON
    if echo "$response" | jq -e '.message' >/dev/null 2>&1; then
        local error_msg
        error_msg=$(echo "$response" | jq -r '.message')
        log_error "Erreur API GitHub: $error_msg"
        
        # Si c'est une erreur de limite de taux, attendre
        if echo "$error_msg" | grep -i "rate limit" >/dev/null 2>&1; then
            api_wait_rate_limit
        fi
        return 1
    fi
    
    # Sauvegarder dans le cache
    echo "$response" > "$cache_file"
    log_debug "Cache mis à jour pour: $url"
    
    # Retourner UNIQUEMENT le JSON, pas les logs DEBUG
    echo "$response"
    return 0
}

# Récupère tous les dépôts avec pagination automatique
api_fetch_all_repos() {
    local context="$1"
    local username="$2"
    local page=1
    local per_page=100
    local all_repos="[]"
    
    log_info "Récupération des dépôts avec pagination automatique..." >&2
    
    # Vérifier d'abord si nous avons un cache complet
    local cache_key
    cache_key=$(api_cache_key "all_repos_${context}_${username}")
    local cache_file="$API_CACHE_DIR/${cache_key}.json"
    
    if api_cache_valid "$cache_file" "$API_CACHE_TTL"; then
        log_debug "Utilisation du cache complet pour tous les dépôts" >&2
        cat "$cache_file"
        return 0
    fi
    
    # Utiliser /user/repos pour l'utilisateur authentifié (dépôts publics + privés)
    # ou /users/:username/repos pour les autres utilisateurs (dépôts publics uniquement)
    local api_url
    if [ "$context" = "users" ] && [ -n "${GITHUB_AUTH_METHOD:-}" ] && [ "$GITHUB_AUTH_METHOD" != "public" ]; then
        # Authentifié et c'est notre propre compte : utiliser /user/repos pour avoir publics + privés
        api_url="https://api.github.com/user/repos"
    else
        # Compte public ou autre utilisateur : utiliser l'endpoint classique
        api_url="$API_BASE_URL/$context/$username/repos"
    fi
    
    while true; do
        local url="$api_url?page=$page&per_page=$per_page&sort=updated&direction=desc&type=all"
        
        log_debug "Récupération page $page..."
        
        local response
        if ! response=$(api_fetch_with_cache "$url"); then
            log_error "Échec de la récupération de la page $page"
            # Si nous avons des dépôts partiels, les retourner
            if [ "$all_repos" != "[]" ]; then
                log_warning "Retour des dépôts partiellement récupérés"
                echo "$all_repos"
                return 0
            fi
            break
        fi
        
        # Debug: afficher la réponse pour diagnostiquer
        log_debug "Réponse API page $page reçue (longueur: ${#response})"
        
        # Vérifier si la réponse est vide ou invalide
        if [ -z "$response" ] || [ "$response" = "null" ] || [ "$response" = "[]" ]; then
            log_debug "Page $page vide ou invalide (réponse: $response), fin de la pagination"
            break
        fi
        
        # Vérifier si c'est un tableau JSON valide
        if ! echo "$response" | jq -e 'type == "array"' >/dev/null 2>&1; then
            log_error "Réponse API invalide pour la page $page (pas un tableau JSON)"
            break
        fi
        
        # Compter le nombre de dépôts dans cette page
        local page_count
        page_count=$(echo "$response" | jq 'length')
        
        if [ "$page_count" -eq 0 ]; then
            log_debug "Page $page contient 0 dépôts, fin de la pagination"
            break
        fi
        
        log_debug "Page $page contient $page_count dépôts"
        
        # Fusionner avec les dépôts existants (seulement si la page n'est pas vide)
        if [ "$page_count" -gt 0 ]; then
            local temp_file1 temp_file2 temp_result
            temp_file1=$(mktemp)
            temp_file2=$(mktemp)
            temp_result=$(mktemp)
            echo "$all_repos" > "$temp_file1"
            echo "$response" > "$temp_file2"
            log_debug "Avant fusion - all_repos: $(cat "$temp_file1" | jq 'length'), response: $(cat "$temp_file2" | jq 'length')"
            jq -s '.[0] + .[1]' "$temp_file1" "$temp_file2" > "$temp_result"
            all_repos=$(cat "$temp_result")
            rm -f "$temp_file1" "$temp_file2" "$temp_result"
            log_debug "Après fusion - Total: $(echo "$all_repos" | jq 'length')"
        fi
        
        # Passer à la page suivante
        page=$((page + 1))
        
        # Petite pause pour éviter de surcharger l'API
        sleep 0.1
    done
    
    local total_count
    total_count=$(echo "$all_repos" | jq 'length')
    
    # Sauvegarder le cache complet
    echo "$all_repos" > "$cache_file"
    log_debug "Cache complet sauvegardé: $total_count dépôts" >&2
    
    log_success "Récupération terminée: $total_count dépôts trouvés" >&2
    
    echo "$all_repos"
    return 0
}

# Récupère le nombre total de dépôts (optimisé)
api_get_total_repos() {
    local context="$1"
    local username="$2"
    
    # Essayer d'abord avec le cache
    local cache_key
    cache_key=$(api_cache_key "total_${context}_${username}")
    local cache_file="$API_CACHE_DIR/${cache_key}.json"
    
    if api_cache_valid "$cache_file" "$API_CACHE_TTL"; then
        local cached_total
        cached_total=$(cat "$cache_file")
        log_debug "Utilisation du cache pour le nombre total de dépôts: $cached_total"
        echo "$cached_total"
        return 0
    fi
    
    # Faire un appel API pour obtenir le nombre total
    # Utiliser /user/repos pour l'utilisateur authentifié, sinon /users/:username/repos
    local api_url
    if [ "$context" = "users" ] && [ -n "${GITHUB_AUTH_METHOD:-}" ] && [ "$GITHUB_AUTH_METHOD" != "public" ]; then
        api_url="https://api.github.com/user/repos"
    else
        api_url="$API_BASE_URL/$context/$username/repos"
    fi
    local url="$api_url?per_page=1&type=all"
    
    local response
    if ! response=$(api_fetch_with_cache "$url"); then
        log_warning "Impossible de récupérer le nombre total de dépôts, utilisation de l'estimation par défaut"
        echo "100"
        return 0
    fi
    
    # Extraire le nombre total depuis les headers de pagination
    local headers
    headers=$(auth_get_headers "$GITHUB_AUTH_METHOD")
    
    local link_header
    link_header=$(eval "curl -s -I $headers -H \"Accept: application/vnd.github.v3+json\" \"$url\"" 2>/dev/null | \
                  grep -i "link:" | cut -d' ' -f2-)
    
    local total=100  # Valeur par défaut
    
    if [ -n "$link_header" ]; then
        # Extraire le nombre total depuis le header Link
        local last_page
        last_page=$(echo "$link_header" | grep -o 'page=[0-9]*' | tail -1 | cut -d'=' -f2)
        
        if [ -n "$last_page" ] && [ "$last_page" -gt 0 ]; then
            total="$last_page"
        fi
    fi
    
    # Sauvegarder dans le cache
    echo "$total" > "$cache_file"
    
    log_debug "Nombre total de dépôts calculé: $total"
    echo "$total"
    return 0
}

# Fonction principale d'initialisation du module API
api_setup() {
    api_init
    
    if [ $? -ne 0 ]; then
        log_error "Échec de l'initialisation du module API"
        return 1
    fi
    
    log_success "Module API GitHub initialisé avec succès"
    return 0
}