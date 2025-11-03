#!/bin/bash

# Configuration de sécurité Bash
set -euo pipefail

# lib/interactive/interactive.sh - Module d'interface interactive
# Gère les modes interactif et non-interactif

# Variables de configuration
INTERACTIVE_MODE="${INTERACTIVE_MODE:-false}"
CONFIRM_MODE="${CONFIRM_MODE:-false}"
AUTO_YES="${AUTO_YES:-false}"

# Initialise le module interactif
interactive_init() {
    log_debug "Module interactif initialisé"
    log_debug "Mode interactif: $INTERACTIVE_MODE"
    log_debug "Mode confirmation: $CONFIRM_MODE"
    log_debug "Mode automatique: $AUTO_YES"
}

# Statistiques interactives
get_interactive_stats() {
    echo "Interactive Statistics:"
    echo "  Interactive mode: ${INTERACTIVE_MODE:-false}"
    echo "  Confirm mode: ${CONFIRM_MODE:-false}"
    echo "  Auto yes: ${AUTO_YES:-false}"
}

# Vérifie si le terminal est interactif
interactive_is_terminal() {
    if [ -t 0 ] && [ -t 1 ]; then
        return 0
    else
        return 1
    fi
}

# Demande une confirmation à l'utilisateur
interactive_confirm() {
    local message="$1"
    local default="${2:-y}"  # y ou n
    
    # Si le mode automatique est activé, retourner la valeur par défaut
    if [ "$AUTO_YES" = "true" ]; then
        log_debug "Mode automatique activé, confirmation automatique: $default"
        if [ "$default" = "y" ]; then
            return 0
        else
            return 1
        fi
    fi
    
    # Si le terminal n'est pas interactif, retourner la valeur par défaut
    if ! interactive_is_terminal; then
        log_debug "Terminal non interactif, confirmation automatique: $default"
        if [ "$default" = "y" ]; then
            return 0
        else
            return 1
        fi
    fi
    
    # Demander confirmation
    while true; do
        if [ "$default" = "y" ]; then
            read -p "$message [Y/n]: " -r response
        else
            read -p "$message [y/N]: " -r response
        fi
        
        case "$response" in
            [Yy]|[Yy][Ee][Ss])
                return 0
                ;;
            [Nn]|[Nn][Oo])
                return 1
                ;;
            "")
                if [ "$default" = "y" ]; then
                    return 0
                else
                    return 1
                fi
                ;;
            *)
                echo "Veuillez répondre par 'y' ou 'n'"
                ;;
        esac
    done
}

# Affiche un résumé détaillé de l'opération
interactive_show_summary() {
    local context="$1"
    local username="$2"
    local destination="$3"
    local total_repos="$4"
    local estimated_size="$5"
    local parallel_jobs="$6"
    local filter_enabled="$7"
    local incremental_mode="$8"
    local auth_method="$9"
    
    log_info "=== Résumé de l'Opération Git Mirror ==="
    log_info "Contexte           : $context"
    log_info "Utilisateur/Org    : $username"
    log_info "Destination        : $destination"
    log_info "Nombre de dépôts   : $total_repos repos"
    log_info "Taille estimée     : ~${estimated_size}MB"
    log_info ""
    log_info "Options activées :"
    
    if [ "$parallel_jobs" -gt 1 ]; then
        log_info " - Parallélisation : $parallel_jobs jobs simultanés"
    fi
    
    if [ "$filter_enabled" = "true" ]; then
        log_info " - Filtre          : Patterns d'exclusion/inclusion"
    fi
    
    if [ "$incremental_mode" = "true" ]; then
        log_info " - Mode incrémental: Oui (seulement repos modifiés)"
    fi
    
    log_info " - Authentification: $auth_method"
    
    if [ "$filter_enabled" = "true" ]; then
        log_info ""
        log_info "Dépôts exclus     : (selon patterns configurés)"
        log_info "Dépôts à traiter  : $total_repos"
    fi
    
    log_info "========================================"
}

# Demande confirmation avant de démarrer
interactive_confirm_start() {
    local context="$1"
    local username="$2"
    local destination="$3"
    local total_repos="$4"
    local estimated_size="$5"
    local parallel_jobs="$6"
    local filter_enabled="$7"
    local incremental_mode="$8"
    local auth_method="$9"
    
    # Afficher le résumé
    interactive_show_summary "$context" "$username" "$destination" "$total_repos" \
                            "$estimated_size" "$parallel_jobs" "$filter_enabled" \
                            "$incremental_mode" "$auth_method"
    
    # Demander confirmation
    if interactive_confirm "Continuer avec cette opération ?"; then
        log_success "Confirmation reçue, démarrage de l'opération"
        return 0
    else
        log_info "Opération annulée par l'utilisateur"
        return 1
    fi
}

# Sélectionne des dépôts à traiter (menu interactif)
interactive_select_repos() {
    local repos_json="$1"
    
    if [ "$INTERACTIVE_MODE" != "true" ]; then
        echo "$repos_json"
        return 0
    fi
    
    if ! interactive_is_terminal; then
        log_warning "Mode interactif activé mais terminal non interactif, traitement de tous les dépôts"
        echo "$repos_json"
        return 0
    fi
    
    # Vérifier si fzf est disponible
    if command -v fzf >/dev/null 2>&1; then
        log_info "Sélection des dépôts avec fzf..."
        
        local selected_repos
        selected_repos=$(echo "$repos_json" | jq -r '.[] | "\(.name) - \(.description // "Pas de description")"' | \
                        fzf --multi --height 20 --border --header "Sélectionnez les dépôts à traiter (Ctrl+A pour tout sélectionner)")
        
        if [ -z "$selected_repos" ]; then
            log_info "Aucun dépôt sélectionné"
            echo "[]"
            return 0
        fi
        
        # Filtrer les dépôts sélectionnés
        # OPTIMISATION: Utiliser jq pour filtrer directement au lieu d'une boucle
        local repo_names_list
        repo_names_list=$(echo "$selected_repos" | cut -d' ' -f1 | jq -R -s 'split("\n") | map(select(. != ""))' 2>/dev/null)
        if [ -n "$repo_names_list" ] && [ "$repo_names_list" != "[]" ]; then
            filtered_repos=$(echo "$repos_json" | jq --argjson names "$repo_names_list" '[.[] | select(.name as $n | $names | index($n) != null)]' 2>/dev/null || echo "[]")
        else
            filtered_repos="[]"
        fi
        
        log_success "Dépôts sélectionnés: $(echo "$filtered_repos" | jq 'length')"
        echo "$filtered_repos"
        return 0
    else
        # Menu simple sans fzf
        log_info "Sélection des dépôts (menu simple)..."
        
        local repo_names
        repo_names=$(echo "$repos_json" | jq -r '.[] | .name')
        
        log_info "Dépôts disponibles:"
        local i=1
        while IFS= read -r repo_name; do
            log_info "  $i. $repo_name"
            i=$((i + 1))
        done <<< "$repo_names"
        
        log_info "  a. Tous les dépôts"
        log_info "  q. Quitter"
        
        read -p "Sélectionnez les dépôts (numéros séparés par des virgules, 'a' pour tous, 'q' pour quitter): " -r selection
        
        case "$selection" in
            [Qq])
                log_info "Sélection annulée"
                echo "[]"
                return 0
                ;;
            [Aa])
                log_success "Tous les dépôts sélectionnés"
                echo "$repos_json"
                return 0
                ;;
            *)
                # Traiter la sélection
                local filtered_repos="[]"
                IFS=',' read -ra numbers <<< "$selection"
                
                # OPTIMISATION: Préparer les indices une seule fois et utiliser jq pour filtrer
                local indices_json
                indices_json=$(printf '%s\n' "${numbers[@]}" | tr -d ' ' | grep -E '^[0-9]+$' | jq -R . | jq -s .)
                if [ -n "$indices_json" ] && [ "$indices_json" != "[]" ]; then
                    local selected_names
                    selected_names=$(echo "$repo_names" | jq -R . | jq -r --argjson indices "$indices_json" '. as $names | $indices | map($names[. - 1] // empty) | map(select(. != null))')
                    if [ -n "$selected_names" ]; then
                        filtered_repos=$(echo "$repos_json" | jq --argjson names "$selected_names" '[.[] | select(.name as $n | ($names | index($n) != null))]')
                    fi
                fi
                
                log_success "Dépôts sélectionnés: $(echo "$filtered_repos" | jq 'length')"
                echo "$filtered_repos"
                return 0
                ;;
        esac
    fi
}

# Affiche une barre de progression
interactive_show_progress() {
    local current="$1"
    local total="$2"
    local message="${3:-Traitement}"
    
    if [ "$INTERACTIVE_MODE" != "true" ] || ! interactive_is_terminal; then
        return 0
    fi
    
    local percentage=$((current * 100 / total))
    local bar_length=50
    local filled_length=$((percentage * bar_length / 100))
    
    local bar=""
    local i=0
    while [ $i -lt $filled_length ]; do
        bar+="="
        i=$((i + 1))
    done
    
    while [ $i -lt $bar_length ]; do
        bar+=" "
        i=$((i + 1))
    done
    
    printf "\r%s [%s] %d%% (%d/%d)" "$message" "$bar" "$percentage" "$current" "$total"
    
    if [ "$current" -eq "$total" ]; then
        echo ""
    fi
}

# Demande confirmation pour continuer après une erreur
interactive_confirm_continue() {
    local error_message="$1"
    
    log_error "$error_message"
    
    if interactive_confirm "Continuer malgré cette erreur ?"; then
        log_info "Continuation de l'opération"
        return 0
    else
        log_info "Arrêt de l'opération"
        return 1
    fi
}

# Fonction principale d'initialisation du module interactif
interactive_setup() {
    if ! interactive_init; then
        log_error "Échec de l'initialisation du module interactif"
        return 1
    fi
    
    if [ "$INTERACTIVE_MODE" = "true" ] || [ "$CONFIRM_MODE" = "true" ]; then
        log_success "Module interactif initialisé avec succès"
        
        if [ "$AUTO_YES" = "true" ]; then
            log_info "Mode automatique activé (pas d'interaction utilisateur)"
        fi
    else
        log_debug "Module interactif désactivé"
    fi
    
    return 0
}