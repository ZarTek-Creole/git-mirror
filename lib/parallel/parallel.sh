#!/bin/bash

# Configuration de sécurité Bash
set -euo pipefail

# lib/parallel/parallel.sh - Module de parallélisation
# Gère l'exécution parallèle des opérations Git avec GNU parallel

# Variables de configuration
PARALLEL_ENABLED="${PARALLEL_ENABLED:-false}"
PARALLEL_JOBS="${PARALLEL_JOBS:-1}"
PARALLEL_TIMEOUT="${PARALLEL_TIMEOUT:-300}"  # 5 minutes par défaut

# Vérifie si GNU parallel est disponible
parallel_check_available() {
    if command -v parallel >/dev/null 2>&1; then
        local version
        version=$(parallel --version 2>&1 | head -1 | grep -o '[0-9]\+\.[0-9]\+' | head -1)
        log_debug "GNU parallel détecté: version $version"
        return 0
    else
        log_warning "GNU parallel non disponible"
        return 1
    fi
}

# Initialise le module de parallélisation
parallel_init() {
    if [ "$PARALLEL_ENABLED" = "true" ]; then
        if ! parallel_check_available; then
            log_error "Parallélisation activée mais GNU parallel non disponible"
            log_info "Installation de GNU parallel..."
            
            # Essayer d'installer GNU parallel
            if command -v apt-get >/dev/null 2>&1; then
                sudo apt-get update && sudo apt-get install -y parallel
            elif command -v yum >/dev/null 2>&1; then
                sudo yum install -y parallel
            elif command -v brew >/dev/null 2>&1; then
                brew install parallel
            else
                log_error "Impossible d'installer GNU parallel automatiquement"
                log_info "Veuillez installer GNU parallel manuellement"
                return 1
            fi
            
            # Vérifier à nouveau après installation
            if ! parallel_check_available; then
                log_error "Échec de l'installation de GNU parallel"
                return 1
            fi
        fi
        
        log_success "Module de parallélisation initialisé: $PARALLEL_JOBS jobs"
    else
        log_debug "Parallélisation désactivée"
    fi
    
    return 0
}

# Exécute une commande en parallèle
parallel_execute() {
    local command="$1"
    local input="$2"
    local jobs="${3:-$PARALLEL_JOBS}"
    
    if [ "$PARALLEL_ENABLED" != "true" ] || [ "$jobs" -eq 1 ]; then
        # Exécution séquentielle
        echo "$input" | while read -r item; do
            eval "$command \"$item\""
        done
        return 0
    fi
    
    # Exécution parallèle
    log_debug "Exécution parallèle avec $jobs jobs"
    
    echo "$input" | parallel -j "$jobs" --timeout "$PARALLEL_TIMEOUT" --halt-on-error 2 "$command"
    
    local exit_code=$?
    
    if [ $exit_code -ne 0 ]; then
        log_warning "Certains jobs parallèles ont échoué (code: $exit_code)"
    fi
    
    return $exit_code
}

# Clone des dépôts en parallèle
parallel_clone_repos() {
    local repos="$1"
    local jobs="${2:-$PARALLEL_JOBS}"
    
    if [ "$PARALLEL_ENABLED" != "true" ] || [ "$jobs" -eq 1 ]; then
        # Exécution séquentielle
        echo "$repos" | while read -r repo; do
            clone_or_update_repo "$repo"
        done
        return 0
    fi
    
    # Exécution parallèle
    log_info "Clonage parallèle de $(echo "$repos" | wc -l) dépôts avec $jobs jobs"
    
    # Créer une fonction wrapper pour parallel
    local wrapper_func
    wrapper_func=$(cat <<'EOF'
clone_wrapper() {
    local repo="$1"
    local job_id="$2"
    
    # Préfixer les logs avec l'ID du job
    log_info "[Job-$job_id] Traitement du dépôt: $repo"
    
    # Exécuter la fonction de clonage
    clone_or_update_repo "$repo"
    
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        log_success "[Job-$job_id] Succès: $repo"
    else
        log_error "[Job-$job_id] Échec: $repo"
    fi
    
    return $exit_code
}
EOF
)
    
    # Exporter la fonction wrapper
    eval "$wrapper_func"
    export -f clone_wrapper
    export -f clone_or_update_repo
    export -f log_info log_success log_error log_debug
    export DEST_DIR BRANCH FILTER NO_CHECKOUT SINGLE_BRANCH DEPTH VERBOSE QUIET DRY_RUN
    
    # Exécuter en parallèle
    echo "$repos" | parallel -j "$jobs" --timeout "$PARALLEL_TIMEOUT" --halt-on-error 2 \
        --joblog "$STATE_DIR/parallel.log" \
        --tagstring "[Job-{= \$job =}]" \
        clone_wrapper {}
    
    local exit_code=$?
    
    if [ $exit_code -ne 0 ]; then
        log_warning "Certains clonages parallèles ont échoué (code: $exit_code)"
        log_info "Consultez le log: $STATE_DIR/parallel.log"
    fi
    
    return $exit_code
}

# Attend la fin de tous les jobs parallèles
parallel_wait_jobs() {
    if [ "$PARALLEL_ENABLED" != "true" ]; then
        return 0
    fi
    
    # Vérifier s'il y a des jobs en cours
    local active_jobs
    active_jobs=$(jobs -r | wc -l)
    
    if [ "$active_jobs" -gt 0 ]; then
        log_info "Attente de la fin de $active_jobs jobs parallèles..."
        wait
        log_success "Tous les jobs parallèles terminés"
    fi
    
    return 0
}

# Obtient les statistiques de parallélisation
parallel_get_stats() {
    if [ ! -f "$STATE_DIR/parallel.log" ]; then
        echo "Aucun log de parallélisation disponible"
        return 0
    fi
    
    local total_jobs
    total_jobs=$(wc -l < "$STATE_DIR/parallel.log")
    local successful_jobs
    successful_jobs=$(grep -c "Exitval:0" "$STATE_DIR/parallel.log" 2>/dev/null || echo "0")
    local failed_jobs
    failed_jobs=$(grep -c "Exitval:[1-9]" "$STATE_DIR/parallel.log" 2>/dev/null || echo "0")
    
    log_info "=== Statistiques de Parallélisation ==="
    log_info "Total jobs: $total_jobs"
    log_info "Succès: $successful_jobs"
    log_info "Échecs: $failed_jobs"
    log_info "Taux de succès: $((successful_jobs * 100 / total_jobs))%"
    log_info "====================================="
}

# Nettoie les fichiers de parallélisation
parallel_cleanup() {
    if [ -f "$STATE_DIR/parallel.log" ]; then
        rm -f "$STATE_DIR/parallel.log"
        log_debug "Log de parallélisation nettoyé"
    fi
}

# Statistiques de parallélisation
get_parallel_stats() {
    local total_jobs="${PARALLEL_JOBS:-1}"
    local enabled="${PARALLEL_ENABLED:-false}"
    
    echo "Parallel Statistics:"
    echo "  Enabled: $enabled"
    echo "  Jobs: $total_jobs"
    echo "  Timeout: ${PARALLEL_TIMEOUT:-300}s"
    
    if [ "$enabled" = "true" ]; then
        echo "  Mode: Multi-process parallelization"
    else
        echo "  Mode: Sequential execution"
    fi
}

# Fonction principale d'initialisation du module de parallélisation
parallel_setup() {
    if ! parallel_init; then
        log_error "Échec de l'initialisation du module de parallélisation"
        return 1
    fi
    
    log_success "Module de parallélisation initialisé avec succès"
    return 0
}