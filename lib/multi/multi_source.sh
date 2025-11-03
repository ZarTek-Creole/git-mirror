#!/bin/bash
# Module: Multi-Sources Support
# Support pour cloner depuis plusieurs sources simultanément

set -euo pipefail

# Parser les sources multiples
parse_multi_sources() {
    local sources="$1"
    local -a users=()
    local -a orgs=()
    
    # Parser format: users:user1,user2 orgs:org1,org2
    while IFS= read -r source; do
        if [[ "$source" =~ ^users:(.+)$ ]]; then
            IFS=',' read -ra user_list <<< "${BASH_REMATCH[1]}"
            users+=("${user_list[@]}")
        elif [[ "$source" =~ ^orgs:(.+)$ ]]; then
            IFS=',' read -ra org_list <<< "${BASH_REMATCH[1]}"
            orgs+=("${org_list[@]}")
        fi
    done <<< "$sources"
    
    # Retourner les listes
    printf '%s\n' "${users[@]}" > /tmp/multi_users.txt
    printf '%s\n' "${orgs[@]}" > /tmp/multi_orgs.txt
}

# Traiter les sources multiples
process_multi_sources() {
    local sources="$1"
    local dest_dir="$2"
    
    parse_multi_sources "$sources"
    
    # Traiter les utilisateurs
    while IFS= read -r user; do
        [ -z "$user" ] && continue
        log_info "Traitement utilisateur: $user"
        # Appel récursif ou traitement direct
    done < /tmp/multi_users.txt
    
    # Traiter les organisations
    while IFS= read -r org; do
        [ -z "$org" ] && continue
        log_info "Traitement organisation: $org"
        # Appel récursif ou traitement direct
    done < /tmp/multi_orgs.txt
    
    rm -f /tmp/multi_users.txt /tmp/multi_orgs.txt
}
