#!/bin/bash
# Module: Multi-Sources Support
# Support pour cloner depuis plusieurs sources simultanément
# Usage: --multi-sources "users:user1,user2 orgs:org1,org2"

set -euo pipefail

# Variables
readonly MULTI_SOURCES_TEMP_DIR="${TMPDIR:-/tmp}/git-mirror-multi-sources"

# Parser les sources multiples
# Format: "users:user1,user2 orgs:org1,org2"
multi_parse_sources() {
    local sources="$1"
    local -a users=()
    local -a orgs=()
    
    mkdir -p "$MULTI_SOURCES_TEMP_DIR"
    
    # Parser chaque partie séparée par espace
    for part in $sources; do
        if [[ "$part" =~ ^users:(.+)$ ]]; then
            IFS=',' read -ra user_list <<< "${BASH_REMATCH[1]}"
            users+=("${user_list[@]}")
        elif [[ "$part" =~ ^orgs:(.+)$ ]]; then
            IFS=',' read -ra org_list <<< "${BASH_REMATCH[1]}"
            orgs+=("${org_list[@]}")
        fi
    done
    
    # Sauvegarder dans des fichiers temporaires
    printf '%s\n' "${users[@]}" > "$MULTI_SOURCES_TEMP_DIR/users.txt" 2>/dev/null || true
    printf '%s\n' "${orgs[@]}" > "$MULTI_SOURCES_TEMP_DIR/orgs.txt" 2>/dev/null || true
    
    log_debug "Multi-Sources parsé: ${#users[@]} utilisateurs, ${#orgs[@]} organisations" 2>/dev/null || echo "Multi-Sources parsé"
    
    echo "${#users[@]} ${#orgs[@]}"
}

# Traiter les sources multiples en appelant le script principal récursivement
multi_process_sources() {
    local sources="$1"
    local script_path="$2"
    shift 2
    local extra_args=("$@")
    
    local counts
    counts=$(multi_parse_sources "$sources")
    
    # Extraire les compteurs
    local user_count org_count
    user_count=$(echo "$counts" | awk '{print $1}')
    org_count=$(echo "$counts" | awk '{print $2}')
    
    # Traiter les utilisateurs
    if [ "$user_count" -gt 0 ] && [ -s "$MULTI_SOURCES_TEMP_DIR/users.txt" ]; then
        log_info "Traitement de $user_count utilisateur(s)..."
        while IFS= read -r user; do
            [ -z "$user" ] && continue
            log_info "→ Traitement utilisateur: $user"
            # Appel récursif au script principal
            bash "$script_path" users "$user" "${extra_args[@]}" || log_warning "Échec pour utilisateur: $user"
        done < "$MULTI_SOURCES_TEMP_DIR/users.txt"
    fi
    
    # Traiter les organisations
    if [ "$org_count" -gt 0 ] && [ -s "$MULTI_SOURCES_TEMP_DIR/orgs.txt" ]; then
        log_info "Traitement de $org_count organisation(s)..."
        while IFS= read -r org; do
            [ -z "$org" ] && continue
            log_info "→ Traitement organisation: $org"
            # Appel récursif au script principal
            bash "$script_path" orgs "$org" "${extra_args[@]}" || log_warning "Échec pour organisation: $org"
        done < "$MULTI_SOURCES_TEMP_DIR/orgs.txt"
    fi
    
    # Nettoyage optionnel (garde les fichiers pour debug si VERBOSE_LEVEL élevé)
    if [ "${VERBOSE_LEVEL:-0}" -lt 2 ]; then
        rm -rf "$MULTI_SOURCES_TEMP_DIR" 2>/dev/null || true
    fi
}

# Valider le format des sources multiples
multi_validate_sources() {
    local sources="$1"
    
    if [ -z "$sources" ]; then
        log_error "Sources multiples non spécifiées" 2>/dev/null || echo "ERREUR: Sources multiples non spécifiées"
        return 1
    fi
    
    # Vérifier le format de base
    if ! echo "$sources" | grep -qE "(users:|orgs:)"; then
        log_error "Format invalide. Utiliser: users:user1,user2 orgs:org1,org2" 2>/dev/null || echo "ERREUR: Format invalide"
        return 1
    fi
    
    return 0
}
