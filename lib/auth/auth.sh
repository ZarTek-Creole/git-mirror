#!/bin/bash

# Configuration de sécurité Bash
set -euo pipefail

# lib/auth/auth.sh - Module d'authentification GitHub
# Gère l'authentification via Token GitHub, SSH ou mode public
# Pattern: Chain of Responsibility

# Variables d'environnement supportées
# GITHUB_TOKEN : token d'accès personnel GitHub
# GITHUB_SSH_KEY : chemin vers clé SSH (optionnel)
# GITHUB_AUTH_METHOD : force méthode (token/ssh/public)

# Menu interactif pour choisir l'authentification
auth_interactive_menu() {
    echo ""
    echo "=== Configuration de l'authentification GitHub ==="
    echo ""
    echo "Choisissez votre méthode d'authentification :"
    echo ""
    echo "1) GitHub CLI (gh) - Recommandé"
    echo "2) Token personnel GitHub"
    echo "3) Clé SSH"
    echo "4) Mode public (sans authentification)"
    echo "5) Annuler"
    echo ""
    
    read -p "Votre choix [1-5] : " choice
    
    case $choice in
        1)
            if command -v gh >/dev/null 2>&1; then
                if gh auth status &>/dev/null; then
                    local gh_token
                    gh_token=$(gh auth token 2>/dev/null)
                    if [ -n "$gh_token" ]; then
                        export GITHUB_TOKEN=$(echo "$gh_token" | tr -d '[:space:]')
                        export GITHUB_AUTH_METHOD="token"
                        echo "✅ GitHub CLI configuré avec succès"
                        return 0
                    fi
                else
                    echo "⚠️  GitHub CLI installé mais non authentifié"
                    echo "   Exécutez: gh auth login"
                    return 1
                fi
            else
                echo "❌ GitHub CLI (gh) non installé"
                echo "   Installation: https://cli.github.com/"
                return 1
            fi
            ;;
        2)
            echo ""
            echo "Créez un token sur: https://github.com/settings/tokens"
            echo "Permissions requises: repo (pour dépôts privés)"
            echo ""
            read -p "Entrez votre token GitHub : " -s token_input
            echo ""
            
            if [ -n "$token_input" ]; then
                export GITHUB_TOKEN=$(echo "$token_input" | tr -d '[:space:]')
                export GITHUB_AUTH_METHOD="token"
                
                # Valider le token
                if auth_validate_token "$GITHUB_TOKEN" >/dev/null 2>&1; then
                    echo "✅ Token validé avec succès"
                    return 0
                else
                    echo "❌ Token invalide"
                    unset GITHUB_TOKEN
                    return 1
                fi
            else
                echo "❌ Token vide"
                return 1
            fi
            ;;
        3)
            if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
                export GITHUB_AUTH_METHOD="ssh"
                echo "✅ Clé SSH GitHub détectée"
                return 0
            else
                echo "❌ Aucune clé SSH GitHub configurée"
                echo "   Guide: https://docs.github.com/en/authentication/connecting-to-github-with-ssh"
                return 1
            fi
            ;;
        4)
            export GITHUB_AUTH_METHOD="public"
            echo "⚠️  Mode public activé (rate limit: 60 req/h)"
            echo "   Certaines fonctionnalités seront limitées"
            return 0
            ;;
        5)
            echo "❌ Configuration annulée"
            return 1
            ;;
        *)
            echo "❌ Choix invalide"
            return 1
            ;;
    esac
}

# Chaîne de responsabilité pour détecter l'authentification (Pattern Chain of Responsibility)
auth_detect_method() {
    local method=""
    
    # PRIORITÉ 1: GitHub CLI (gh) - Méthode recommandée
    if command -v gh >/dev/null 2>&1; then
        local gh_token
        if gh_token=$(gh auth token 2>/dev/null) && [ -n "$gh_token" ]; then
            # Token gh trouvé, le nettoyer et l'utiliser
            export GITHUB_TOKEN=$(echo "$gh_token" | tr -d '[:space:]')
            log_debug_stderr "Token GitHub détecté via GitHub CLI (gh)"
            
            # Valider le token
            if auth_validate_token "$GITHUB_TOKEN" >/dev/null 2>&1; then
                method="token"
                log_debug_stderr "Token GitHub CLI validé avec succès"
                echo "$method"
                return 0
            else
                log_debug_stderr "Token GitHub CLI invalide, essai autres méthodes"
            fi
        fi
    fi
    
    # PRIORITÉ 2: Token GitHub dans variable d'environnement
    if [ -n "${GITHUB_TOKEN:-}" ]; then
        # Nettoyer le token (supprimer les espaces et les nouvelles lignes)
        local clean_token
        clean_token=$(echo "$GITHUB_TOKEN" | tr -d '[:space:]')
        
        # Vérifier le format basique du token
        if [[ "$clean_token" =~ ^[a-f0-9]{40}$ ]] || [[ "$clean_token" =~ ^gh[opru]_[a-zA-Z0-9]{36}$ ]]; then
            # Format valide, tester avec l'API
            if auth_validate_token "$clean_token" >/dev/null 2>&1; then
                method="token"
                log_debug_stderr "Token GitHub détecté et validé"
                echo "$method"
                return 0
            else
                log_debug_stderr "Token GitHub présent (format valide) mais validation API échouée, essai mode public"
            fi
        else
            log_debug_stderr "Token GitHub présent mais format invalide, essai mode public"
        fi
    fi
    
    # PRIORITÉ 3: Clé SSH GitHub configurée
    if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        method="ssh"
        log_debug_stderr "Clé SSH GitHub détectée"
        echo "$method"
        return 0
    fi
    
    # PRIORITÉ 4: Mode public (fallback)
    method="public"
    log_debug_stderr "Aucune authentification détectée, utilisation du mode public"
    echo "$method"
    return 0
}

# Valide le format et les permissions d'un token GitHub
auth_validate_token() {
    local token="$1"
    
    if [ -z "$token" ]; then
        log_error "Token GitHub manquant"
        return 1
    fi
    
    # Vérifier le format du token (40 caractères hexadécimaux ou token moderne)
    if ! [[ "$token" =~ ^[a-f0-9]{40}$ ]] && ! [[ "$token" =~ ^ghp_[a-zA-Z0-9]{36}$ ]] && ! [[ "$token" =~ ^gho_[a-zA-Z0-9]{36}$ ]] && ! [[ "$token" =~ ^ghu_[a-zA-Z0-9]{36}$ ]] && ! [[ "$token" =~ ^ghs_[a-zA-Z0-9]{36}$ ]] && ! [[ "$token" =~ ^ghr_[a-zA-Z0-9]{36}$ ]]; then
        log_error "Format de token GitHub invalide"
        log_info "Format attendu: 40 caractères hexadécimaux ou token moderne (ghp_, gho_, etc.)"
        return 1
    fi
    
    # Tester le token avec une requête API simple
    local response
    if ! response=$(curl -s -H "Authorization: token $token" \
                   -H "Accept: application/vnd.github.v3+json" \
                   "https://api.github.com/user" 2>/dev/null); then
        log_error "Impossible de valider le token GitHub (erreur réseau)"
        return 1
    fi
    
    # Vérifier si la réponse contient une erreur
    if echo "$response" | jq -e '.message' >/dev/null 2>&1; then
        local error_msg
        error_msg=$(echo "$response" | jq -r '.message')
        log_error "Token GitHub invalide: $error_msg"
        return 1
    fi
    
    # Vérifier les permissions du token
    local scopes
    scopes=$(curl -s -I -H "Authorization: token $token" \
                  -H "Accept: application/vnd.github.v3+json" \
                  "https://api.github.com/user" 2>/dev/null | \
                  grep -i "x-oauth-scopes:" | cut -d' ' -f2-)
    
    if [ -n "$scopes" ]; then
        log_debug "Permissions du token: $scopes"
        
        # Vérifier si le token a au moins les permissions de lecture
        if ! echo "$scopes" | grep -q "repo"; then
            log_warning "Le token n'a pas les permissions 'repo' - certains dépôts privés pourraient être inaccessibles"
        fi
    fi
    
    log_success "Token GitHub validé avec succès"
    return 0
}

# Retourne les headers curl avec authentification
auth_get_headers() {
    local method="$1"
    local header_value=""
    
    case "$method" in
        token)
            if [ -n "${GITHUB_TOKEN:-}" ]; then
                # Retourner la valeur du header pour utilisation avec -H
                header_value="Authorization: token $GITHUB_TOKEN"
            fi
            ;;
        ssh)
            # Pour SSH, pas de headers spéciaux nécessaires
            header_value=""
            ;;
        public)
            # Mode public, pas d'authentification
            header_value=""
            ;;
    esac
    
    echo "$header_value"
}

# Transforme une URL HTTPS en SSH ou vice versa selon la méthode d'auth
auth_transform_url() {
    local url="$1"
    local method="$2"
    local transformed_url="$url"
    
    case "$method" in
        ssh)
            # Convertir HTTPS en SSH
            if [[ "$url" =~ ^https://github\.com/(.+)$ ]]; then
                transformed_url="git@github.com:${BASH_REMATCH[1]}"
            fi
            ;;
        token|public)
            # Convertir SSH en HTTPS
            if [[ "$url" =~ ^git@github\.com:(.+)$ ]]; then
                transformed_url="https://github.com/${BASH_REMATCH[1]}"
            fi
            ;;
    esac
    
    echo "$transformed_url"
}

# Initialise l'authentification et retourne la méthode utilisée
auth_init() {
    local method=""
    
    # Si méthode forcée, l'utiliser directement
    if [ -n "${GITHUB_AUTH_METHOD:-}" ]; then
        case "$GITHUB_AUTH_METHOD" in
            token)
                if [ -n "${GITHUB_TOKEN:-}" ]; then
                    if auth_validate_token "$GITHUB_TOKEN" >/dev/null 2>&1; then
                        export GITHUB_AUTH_METHOD="token"
                        return 0
                    else
                        log_error_stderr "Token GitHub invalide"
                        return 1
                    fi
                else
                    log_error_stderr "Token GitHub requis mais non fourni"
                    return 1
                fi
                ;;
            ssh|public)
                export GITHUB_AUTH_METHOD="$GITHUB_AUTH_METHOD"
                return 0
                ;;
            *)
                log_error_stderr "Méthode d'authentification invalide: $GITHUB_AUTH_METHOD"
                return 1
                ;;
        esac
    fi
    
    # Détection automatique
    if ! method=$(auth_detect_method 2>/dev/null) || [ -z "$method" ]; then
        return 1
    fi
    
    log_info_stderr "Méthode d'authentification détectée: $method"
    
    # Valider le token si nécessaire
    if [ "$method" = "token" ]; then
        if ! auth_validate_token "$GITHUB_TOKEN" >/dev/null 2>&1; then
            log_error_stderr "Échec de la validation du token GitHub"
            return 1
        fi
    fi
    
    # Tester la connexion SSH si nécessaire
    if [ "$method" = "ssh" ]; then
        if ! ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
            log_error_stderr "Échec de l'authentification SSH avec GitHub"
            return 1
        fi
        log_success_stderr "Authentification SSH réussie"
    fi
    
    # Exporter la méthode pour qu'elle soit disponible
    export GITHUB_AUTH_METHOD="$method"
    
    # Ne pas retourner la méthode via stdout (pour éviter la pollution des logs)
    return 0
}

# Fonction principale d'authentification avec menu interactif
auth_setup() {
    local method=""
    
    # Si aucune méthode n'a été détectée automatiquement, proposer le menu
    if ! method=$(auth_detect_method 2>/dev/null) || [ -z "$method" ] || [ "$method" = "public" ]; then
        # Mode interactif uniquement si terminal et pas de --yes
        if [ -t 0 ] && [ "${YES:-false}" != "true" ] && [ -z "${GITHUB_AUTH_METHOD:-}" ]; then
            echo ""
            log_warning_stderr "Aucune authentification GitHub détectée"
            read -p "Voulez-vous configurer l'authentification maintenant ? (O/n) " -r
            if [[ ! $REPLY =~ ^[Nn]$ ]]; then
                if ! auth_interactive_menu; then
                    log_error_stderr "Configuration d'authentification annulée ou échouée"
                    export GITHUB_AUTH_METHOD="public"
                fi
            fi
        fi
    fi
    
    # Détecter et initialiser la méthode d'authentification
    if ! auth_init; then
        log_error_stderr "Impossible d'initialiser l'authentification"
        return 1
    fi
    
    # La méthode est déjà exportée dans auth_init
    local final_method="${GITHUB_AUTH_METHOD:-public}"
    
    log_success_stderr "Authentification configurée: $final_method"
    # Ne pas retourner la méthode via stdout (pour éviter la pollution des logs)
    return 0
}