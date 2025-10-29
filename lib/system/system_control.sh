#!/bin/bash
# lib/system/system_control.sh - Module de contrôle système
# Description: Gestion de ulimit, nice, ionice pour optimisation système

set -euo pipefail

# Variables de configuration
SYSTEM_RESOURCE_LIMITS="${SYSTEM_RESOURCE_LIMITS:-false}"
NICE_PRIORITY="${NICE_PRIORITY:-10}"  # 0-19, plus élevé = moins prioritaire
IONICE_CLASS="${IONICE_CLASS:-2}"     # 1=RT, 2=BE, 3=Idle
IONICE_LEVEL="${IONICE_LEVEL:-4}"     # 0-7 pour RT et BE

# Appliquer les limites de ressources systèmeique
apply_resource_limits() {
    if [ "$SYSTEM_RESOURCE_LIMITS" != "true" ]; then
        return 0
    fi
    
    log_info "=== Application des limites de ressources système ==="
    
    # Limite du nombre de fichiers ouverts simultanément (important pour Git massif)
    if ulimit -n 10000 2>/dev/null; then
        log_success "✓ File descriptors limit: $(ulimit -n)"
    else
        log_warning "Impossible de modifier la limite de file descriptors"
    fi
    
    # Limite de mémoire virtuelle
    if ulimit -v unlimited 2>/dev/null; then
        log_success "✓ Virtual memory: unlimited"
    else
        log_warning "Impossible de modifier la limite de mémoire virtuelle"
    fi
    
    # Limite de processus
    if ulimit -u unlimited 2>/dev/null; then
        log_success "✓ Processes: unlimited"
    else
        log_warning "Impossible de modifier la limite de processus"
    fi
    
    return 0
}

# Appliquer la priorité nice (CPU)
apply_nice_priority() {
    if [ "$SYSTEM_RESOURCE_LIMITS" != "true" ]; then
        return 0
    fi
    
    log_info "Application de la priorité CPU nice=$NICE_PRIORITY"
    
    # Vérifier si nice est disponible
    if ! command -v nice >/dev/null 2>&1; then
        log_warning "nice non disponible, impossible d'appliquer la priorité CPU"
        return 1
    fi
    
    # Exécuter avec nice
    if nice -n "$NICE_PRIORITY" true 2>/dev/null; then
        export SYSTEM_NICE_SET=true
        log_success "✓ Priorité CPU nice=$NICE_PRIORITY appliquée"
    else
        log_warning "Impossible d'appliquer la priorité CPU nice"
        return 1
    fi
    
    return 0
}

# Appliquer la priorité ionice (I/O)
apply_ionice_priority() {
    if [ "$SYSTEM_RESOURCE_LIMITS" != "true" ]; then
        return 0
    fi
    
    log_info "Application de la priorité I/O ionice=$IONICE_CLASS:$IONICE_LEVEL"
    
    # Vérifier si ionice est disponible
    if ! command -v ionice >/dev/null 2>&1; then
        log_warning "ionice non disponible, impossible d'appliquer la priorité I/O"
        return 1
    fi
    
    # Exécuter avec ionice
    if ionice antiope-c "$IONICE_CLASS" -n "$IONICE_LEVEL" true 2>/dev/null; then
        export SYSTEM_IONICE_SET=true
        log_success "✓ Priorité I/O ionice=$IONICE_CLASS:$IONICE_LEVEL appliquée"
    else
        log_warning "Impossible d'appliquer la priorité I/O ionice"
        return 1
    fi
    
    return 0
}

# Appliquer la compression réseau SSH
apply_network_compression() {
    if [ "$SYSTEM_RESOURCE_LIMITS" != "true" ]; then
        return 0
    fi
    
    log_info "Configuration de la compression réseau SSH"
    
    # Activer la compression SSH pour réduire la bande passante
    export GIT_SSH_COMMAND="ssh -o Compression=yes -o CompressionLevel=6"
    log_success "✓ Compression réseau SSH activée"
    
    return 0
}

# Exécuter une commande avec toutes les optimisations système appliquées
system_execute_with_limits() {
    local command="$1"
    
    if [ "$SYSTEM_RESOURCE_LIMITS" != "true" ]; then
        eval "$command"
        return $?
    fi
    
    # Construire la commande avec toutes les optimisations
    local optimized_command=""
    
    # Ajouter ionice si disponible
    if command -v ionice >/dev/null 2>&1 && [ -n "${SYSTEM_IONICE_SET:-}" ]; then
        optimized_command="ionice -c $IONICE_CLASS -n $IONICE_LEVEL"
    fi
    
    # Ajouter nice si disponible
    if command -v nice >/dev/null 2>&1 && [ -n "${SYSTEM_NICE_SET:-}" ]; then
        optimized_command="$optimized_command nice -n $NICE_PRIORITY"
    fi
    
    # Ajouter la commande finale
    optimized_command="$optimized_command $command"
    
    log_debug "Commande optimisée: $optimized_command"
    
    eval "$optimized_command"
    return $?
}

# Initialiser le module de contrôle systèmeique
system_control_init() {
    if [ "$SYSTEM_RESOURCE_LIMITS" = "true" ]; then
        apply_resource_limits
        apply_nice_priority
        apply_ionice_priority
        apply_network_compression
        
        log_success "Module de contrôle système initialisé"
    else
        log_debug "Module de contrôle système désactivé"
    fi
    
    return 0
}

# Afficher l'état actuel des limites systèmeiques
system_show_limits() {
    log_info "=== État des Limites Système ==="
    log_info "File descriptors: $(ulimit -n)"
    log_info "Virtual memory: $(ulimit -v)"
    log_info "CPU priority (nice): $(nice 2>/dev/null || echo 'not set')"
    log_info "I/O priority (ionice): $(ionice -p $$ 2>/dev/null || echo 'not set')"
    log_info "Network compression: $GIT_SSH_COMMAND"
    log_info "=================================="
}

# Exporter les fonctions
export -f apply_resource_limits apply_nice_priority apply_ionice_priority apply_network_compression \
         system_execute_with_limits system_control_init system_show_limits

