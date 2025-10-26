#!/bin/bash
# lib/utils/profiling.sh - Module de profiling de performance
# Aide à analyser les performances et identifier les bottlenecks

# Configuration
PROFILING_ENABLED="${PROFILING_ENABLED:-false}"
PROFILING_LOG="${PROFILING_LOG:-.git-mirror-profile.log}"

# Variables globales
declare -A PROFILING_TIMERS=()
declare -A PROFILING_COUNTERS=()

# Démarrer un chronomètre de profiling
profiling_start() {
    local timer_name="$1"
    
    if [ "$PROFILING_ENABLED" = "true" ]; then
        PROFILING_TIMERS["$timer_name"]=$(date +%s.%N)
        log_debug "[PROFILE] Démarrage: $timer_name"
    fi
}

# Arrêter un chronomètre de profiling
profiling_stop() {
    local timer_name="$1"
    
    if [ "$PROFILING_ENABLED" = "true" ] && [ -n "${PROFILING_TIMERS[$timer_name]:-}" ]; then
        local start_time="${PROFILING_TIMERS[$timer_name]}"
        local end_time
        end_time=$(date +%s.%N)
        local duration
        duration=$(echo "$end_time - $start_time" | bc -l)
        
        log_debug "[PROFILE] Arrêt: $timer_name (durée: ${duration}s)"
        
        # Enregistrer dans le log
        echo "$(date '+%Y-%m-%d %H:%M:%S') - PROFILE: $timer_name - ${duration}s" >> "$PROFILING_LOG"
        
        unset PROFILING_TIMERS["$timer_name"]
    fi
}

# Incrémenter un compteur
profiling_increment() {
    local counter_name="$1"
    
    if [ "$PROFILING_ENABLED" = "true" ]; then
        PROFILING_COUNTERS["$counter_name"]=$((${PROFILING_COUNTERS[$counter_name]:-0} + 1))
    fi
}

# Obtenir le compteur
profiling_get() {
    local counter_name="$1"
    echo "${PROFILING_COUNTERS[$counter_name]:-0}"
}

# Afficher le résumé de profiling
profiling_summary() {
    if [ "$PROFILING_ENABLED" != "true" ]; then
        return 0
    fi
    
    log_info "=== Profiling Summary ==="
    
    # Afficher les compteurs
    for counter in "${!PROFILING_COUNTERS[@]}"; do
        log_info "Counter $counter: ${PROFILING_COUNTERS[$counter]}"
    done
    
    # Afficher le log de profiling
    if [ -f "$PROFILING_LOG" ]; then
        log_info "Profiling log: $PROFILING_LOG"
        if [ "$VERBOSE_LEVEL" -ge 2 ]; then
            tail -20 "$PROFILING_LOG"
        fi
    fi
    
    log_info "========================"
}

# Activer le profiling
profiling_enable() {
    export PROFILING_ENABLED=true
    rm -f "$PROFILING_LOG" 2>/dev/null || true
    log_info "Profiling activé: log=$PROFILING_LOG"
}

# Désactiver le profiling
profiling_disable() {
    export PROFILING_ENABLED=false
    log_info "Profiling désactivé"
}

# Exporter les fonctions
export -f profiling_start profiling_stop profiling_increment profiling_get profiling_summary profiling_enable profiling_disable
