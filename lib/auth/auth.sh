#!/bin/bash
# lib/auth/auth.sh - Module d'authentification GitHub
# Gère l'authentification via Token GitHub, SSH ou mode public

# Variables d'environnement supportées
# GITHUB_TOKEN : token d'accès personnel GitHub
# GITHUB_SSH_KEY : chemin vers clé SSH (optionnel)
# GITHUB_AUTH_METHOD : force méthode (token/ssh/public)

# Détecte la méthode d'authentification disponible
auth_detect_method() {
    local method=""
    
    # Vérifier si un token GitHub est disponible et valide
    if [ -n "${GITHUB_TOKEN:-}" ]; then
        if auth_validate_token "$GITHUB_TOKEN" >/dev/null 2>&1; then
            method="token"
            log_debug_stderr "Token GitHub détecté et validé"
        else
            log_warning_stderr "Token GitHub présent mais invalide, utilisation du mode public"
            method="public"
        fi
    # Vérifier si une clé SSH est configurée
    elif ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        method="ssh"
        log_debug_stderr "Clé SSH GitHub détectée"
    else
        method="public"
        log_debug_stderr "Aucune authentification détectée, utilisation du mode public"
    fi
    
    # Forcer une méthode si spécifiée
    if [ -n "${GITHUB_AUTH_METHOD:-}" ]; then
        case "$GITHUB_AUTH_METHOD" in
            token)
                if [ -n "${GITHUB_TOKEN:-}" ]; then
                    method="token"
                else
                    log_error_stderr "Token GitHub requis mais non fourni"
                    return 1
                fi
                ;;
            ssh|public)
                method="$GITHUB_AUTH_METHOD"
                ;;
            *)
                log_error_stderr "Méthode d'authentification invalide: $GITHUB_AUTH_METHOD"
                return 1
                ;;
        esac
    fi
    
    echo "$method"
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
    response=$(curl -s -H "Authorization: token $token" \
                   -H "Accept: application/vnd.github.v3+json" \
                   "https://api.github.com/user" 2>/dev/null)
    
    if [ $? -ne 0 ]; then
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
    local headers=""
    
    case "$method" in
        token)
            if [ -n "${GITHUB_TOKEN:-}" ]; then
                headers="-H \"Authorization: token $GITHUB_TOKEN\""
            fi
            ;;
        ssh)
            # Pour SSH, pas de headers spéciaux nécessaires
            headers=""
            ;;
        public)
            # Mode public, pas d'authentification
            headers=""
            ;;
    esac
    
    echo "$headers"
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
    local method
    method=$(auth_detect_method 2>/dev/null)
    
    if [ $? -ne 0 ] || [ -z "$method" ]; then
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

# Fonction principale d'authentification
auth_setup() {
    # Détecter et initialiser la méthode d'authentification
    auth_init
    
    if [ $? -ne 0 ]; then
        log_error_stderr "Impossible d'initialiser l'authentification"
        return 1
    fi
    
    # La méthode est déjà exportée dans auth_init
    local method="${GITHUB_AUTH_METHOD:-public}"
    
    log_success_stderr "Authentification configurée: $method"
    # Ne pas retourner la méthode via stdout (pour éviter la pollution des logs)
    return 0
}