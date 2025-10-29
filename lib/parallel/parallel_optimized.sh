#!/bin/bash
# lib/parallel/parallel_optimized.sh - Module de parallélisation optimisé
# Description: Parallélisation dynamique adaptative avec auto-tuning

set -euo pipefail

# Variables de configuration
PARALLEL_AUTO_TUNE="${PARALLEL_AUTO_TUNE:-false}"
PARALLEL_DYNAMIC_JOBS="${PARALLEL_DYNAMIC_JOBS:-true}"
PARALLEL_MIN_JOBS="${PARALLEL_MIN_JOBS:-1}"
PARALLEL_MAX_JOBS="${PARALLEL_MAX_JOBS:-50}"

# Fonction: Calculer le nombre optimal de jobs
calculate_optimal_jobs() {
    local requested_jobs="$1"
    local cpu_count
    cpu_count=$(nproc 2>/dev/null || echo "2")
    local memory_gb
    memory_gb=$(free -g | awk '/^Mem:/ {print $2}' 2>/dev/null || echo "4")
    
    # Calculer le nombre optimal basé sur:
    # - CPU cores disponibles
    # - Mémoire disponible (1 job = ~500MB estimé)
    # - Réseau (bande passante limitée)
    local optimal_cpu=$((cpu_count * 2))  # 2 jobs par core
    local optimal_mem=$((memory_gb * 2))  # 2 jobs par GB
    
    # Prendre le minimum pour ne pas surcharger
    local optimal=$((optimal_cpu < optimal_mem ? optimal_cpu : optimal_mem))
    
    # Respecter les limites configurées
    if [ "$optimal" -lt "$PARALLEL_MIN_JOBS" ]; then
        optimal="$PARALLEL_MIN_JOBS"
    fi
    if [ "$optimal" -gt "$PARALLEL_MAX_JOBS" ]; then
        optimal="$PARALLEL_MAX_JOBS"
    fi
    
    # Si l'utilisateur a spécifié un nombre, l'utiliser s'il est raisonnable
    if [ "$requested_jobs" -gt 0 ] && [ "$requested_jobs" -le "$optimal" ]; then
        echo "$requested_jobs"
    else
        echo "$optimal"
    fi
}

# Fonction: Vérifier la connectivité réseau
check_network_connectivity() {
    local github_host="github.com"
    local timeout="${1:-5}"
    
    if command -v timeout >/dev/null 2>&1; then
        if timeout "$timeout" ping -c 1 "$github_host" >/dev/null 2>&1; then
            return 0
        fi
    else
        if ping -c 1 -W "$timeout" "$github_host" >/dev/null 2>&1; then
            return 0
        fi
    fi
    
    return 1
}

# Fonction: Vérifier les quotas API GitHub
check_api_quota() {
    local token="${GITHUB_TOKEN:-}"
    
    if [ -z "$token" ]; then
        log_warning "Pas de token GitHub - quota limité"
        return 1
    fi
    
    local quota_response
    quota_response=$(curl -s -H "Authorization: token $token" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/rate_limit" 2>/dev/null)
    
    if [ -z "$quota_response" ]; then
        log_warning "Impossible de vérifier le quota API"
        return 1
    fi
    
    local remaining limit
    remaining=$(echo "$quota_response" | jq -r '.resources.core.remaining' 2>/dev/null)
    limit=$(echo "$quota_response" | jq -r '.resources.core.limit' 2>/dev/null)
    
    if [ -z "$remaining" ] || [ -z "$limit" ]; then
        log_warning "Impossible de parser le quota API"
        return 1
    fi
    
    local percentage
    percentage=$((remaining * 100 / limit))
    
    log_info "Quota API GitHub: $remaining/$limit ($percentage%)"
    
    # Avertir si < 10% du quota restant
    if [ "$percentage" -lt 10 ]; then
        log_warning "Quota API très faible (< 10%)"
        return 1
    fi
    
    return 0
}

# Fonction: Ajuster dynamiquement les jobs en fonction des performances
adjust_jobs_dynamically() {
    local current_jobs="$1"
    local success_count="$2"
    local error_count="$3"
    
    local total=$((success_count + error_count))
    
    if [ "$total" -eq 0 ]; then
        echo "$current_jobs"
        return
    fi
    
    local error_rate
    error_rate=$((error_count * 100 / total))
    
    # Si taux d'erreur > 50%, réduire les jobs
    if [ "$error_rate" -gt 50 ]; then
        local new_jobs=$((current_jobs / 2))
        if [ "$new_jobs" -lt "$PARALLEL_MIN_JOBS" ]; then
            new_jobs="$PARALLEL_MIN_JOBS"
        fi
        log_warning "Taux d'erreur élevé ($error_rate%) - Réduction des jobs à $new_jobs"
        echo "$new_jobs"
    # Si taux d'erreur < 10% et pas au max, augmenter les jobs
    elif [ "$error_rate" -lt 10 ] && [ "$current_jobs" -lt "$PARALLEL_MAX_JOBS" ]; then
        local new_jobs=$((current_jobs * 2))
        if [ "$new_jobs" -gt "$PARALLEL_MAX_JOBS" ]; then
            new_jobs="$PARALLEL_MAX_JOBS"
        fi
        log_info "Performance excellente ($error_rate% erreurs) - Augmentation des jobs à $new_jobs"
        echo "$new_jobs"
    else
        echo "$current_jobs"
    fi
}

# Fonction: Vérifications préalables complètes
preflight_checks() {
    log_info "=== Vérifications Préalables ==="
    
    local checks_passed=0
    local checks_failed=0
    
    # Check 1: Connectivité réseau
    if check_network_connectivity; then
        log_success "✓ Connectivité réseau: OK"
        ((checks_passed++))
    else
        log_error "✗ Connectivité réseau: ÉCHEC"
        ((checks_failed++))
    fi
    
    # Check 2: Quota API GitHub
    if check_api_quota; then
        log_success "✓ Quota API GitHub: OK"
        ((checks_passed++))
    else
        log_warning "✗ Quota API GitHub: Problèmes détectés"
        ((checks_failed++))
    fi
    
    # Check 3: GNU Parallel disponible
    if command -v parallel >/dev/null 2>&1; then
        log_success "✓ GNU Parallel: Disponible"
        ((checks_passed++))
    else
        log_error "✗ GNU Parallel: Non disponible"
        ((checks_failed++))
    fi
    
    # Check 4: Espace disque
    local available_space
    if available_space=$(df -BG "$DEST_DIR" 2>/dev/null | tail -1 | awk '{print $4}' | sed 's/G//'); then
        if [ "$available_space" -gt 10 ]; then
            log_success "✓ Espace disque: ${available_space}GB disponible"
            ((checks_passed++))
        else
            log_warning "✗ Espace disque: ${available_space}GB disponible (faible)"
            ((checks_failed++))
        fi
    else
        log_warning "✗ Espace disque: Impossible à vérifier"
        ((checks_failed++))
    fi
    
    log_info "=== Résultat: $checks_passed/$((checks_passed + checks_failed)) vérifications OK ==="
    
    # Retourner 0 si au moins 3 checks passés, sinon 1
    if [ "$checks_passed" -ge 3 ]; then
        return 0
    else
        return 1
    fi
}

# Exporter les fonctions
export -f calculate_optimal_jobs check_network_connectivity check_api_quota adjust_jobs_dynamically preflight_checks

