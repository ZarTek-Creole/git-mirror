#!/bin/bash
# Script Principal: git-mirror.sh (Version Modulaire)
# Description: Script principal utilisant l'architecture modulaire
# Pattern: Facade + Command + Observer
# Author: ZarTek-Creole
# Date: 2025-10-25

# Configuration de sécurité Bash
set -euo pipefail

# Informations du script
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
readonly SCRIPT_DIR
readonly SCRIPT_VERSION="2.0.0"

# Répertoires des modules
readonly LIB_DIR="$SCRIPT_DIR/lib"
readonly CONFIG_DIR="$SCRIPT_DIR/config"

# Charger les modules
source "$LIB_DIR/logging/logger.sh"
source "$CONFIG_DIR/config.sh"
source "$LIB_DIR/auth/auth.sh"
source "$LIB_DIR/api/github_api.sh"
source "$LIB_DIR/validation/validation.sh"
source "$LIB_DIR/git/git_ops.sh"
source "$LIB_DIR/cache/cache.sh"
source "$LIB_DIR/parallel/parallel.sh"
source "$LIB_DIR/filters/filters.sh"
source "$LIB_DIR/metrics/metrics.sh"
source "$LIB_DIR/interactive/interactive.sh"
source "$LIB_DIR/state/state.sh"
source "$LIB_DIR/incremental/incremental.sh"
source "$LIB_DIR/utils/profiling.sh"
source "$LIB_DIR/multi/multi_source.sh" 2>/dev/null || true

    # Variables globales
INTERRUPTED=false
success_repos=0
failed_repos=0
total_repos=0
counter=0
NO_CACHE=false
MULTI_SOURCES_ENABLED=false
MULTI_SOURCES=""

# Réinitialiser PROFILING_ENABLED après le chargement du module (pour éviter readonly)
PROFILING_ENABLED="${PROFILING_ENABLED:-false}"

# Fonction d'aide
show_help() {
    echo "Git Mirror - Version $SCRIPT_VERSION"
    echo "Usage: $0 [OPTIONS] context username_or_orgname"
    echo ""
    echo "Arguments:"
    echo "  context              Type de contexte (users ou orgs)"
    echo "  username_or_orgname  Nom d'utilisateur ou d'organisation GitHub"
    echo ""
    echo "Options:"
    echo "  -d, --destination DIR    Répertoire de destination (défaut: ./repositories)"
    echo "  -b, --branch BRANCH      Branche spécifique à cloner (défaut: branche par défaut)"
    echo "  -f, --filter FILTER       Filtre Git pour le clonage partiel (ex: blob:none)"
    echo "  -n, --no-checkout        Cloner sans checkout initial"
    echo "  -s, --single-branch      Cloner une seule branche"
    echo "  --depth DEPTH            Profondeur du clonage shallow (défaut: 1)"
    echo "  --timeout SECONDS        Timeout pour les opérations Git (défaut: 30)"
    echo "  --parallel JOBS          Nombre de jobs parallèles (défaut: 1, nécessite GNU parallel)"
    echo "  --resume                 Reprendre une exécution interrompue"
    echo "  --incremental            Mode incrémental (traite seulement les repos modifiés)"
    echo "  --exclude PATTERN        Exclure les repos correspondant au pattern (peut être utilisé plusieurs fois)"
    echo "  --exclude-file FILE      Lire les patterns d'exclusion depuis un fichier"
    echo "  --include PATTERN        Inclure uniquement les repos correspondant au pattern (peut être utilisé plusieurs fois)"
    echo "  --include-file FILE      Lire les patterns d'inclusion depuis un fichier"
    echo "  --metrics FILE           Exporter les métriques vers un fichier (formats: json,csv,html)"
    echo "  --interactive            Mode interactif avec confirmations"
    echo "  --confirm                Afficher un résumé et demander confirmation avant de commencer"
    echo "  --yes, -y                Mode automatique (ignorer toutes les confirmations)"
    echo "  -v, --verbose            Mode verbeux (peut être utilisé plusieurs fois: -vv, -vvv)"
    echo "  -q, --quiet              Mode silencieux (sortie minimale)"
    echo "  --dry-run                Simulation sans actions réelles"
    echo "  --profile                Active le profiling de performance"
    echo "  --skip-count             Éviter le calcul du nombre total de dépôts (utile si limite API)"
    echo "  --no-cache               Désactiver l'utilisation du cache API (forcer les appels API)"
    echo "  --repo-type TYPE         Type de dépôts à récupérer : all, public, private (défaut: all)"
    echo "  --exclude-forks          Exclure les dépôts forké de la récupération"
    echo "  --multi-sources SOURCES  Traiter plusieurs sources (format: users:u1,u2 orgs:o1,o2)"
    echo "  -h, --help               Afficher cette aide"
    echo ""
    echo "Exemples:"
    echo "  $0 users ZarTek-Creole"
    echo "  $0 -d /path/to/repos users ZarTek-Creole"
    echo "  $0 -b main -f blob:none users ZarTek-Creole"
    echo "  $0 -s -n --depth 5 orgs microsoft"
    echo "  $0 --dry-run -vv users microsoft"
    echo "  $0 -q users microsoft"
    echo "  $0 --resume users microsoft"
    echo "  $0 --incremental users microsoft"
    echo "  $0 --repo-type private users ZarTek-Creole"
    echo "  $0 --repo-type public users ZarTek-Creole"
    echo "  $0 --exclude-forks users ZarTek-Creole"
    echo "  $0 --multi-sources \"users:user1,user2 orgs:org1,org2\""
    echo ""
    echo "Dépendances:"
    echo "  Obligatoires: git >= 2.25, jq >= 1.6, curl >= 7.68"
    echo "  Optionnelles: GNU parallel (pour --parallel), SSH keys (pour auth SSH)"
    echo ""
    echo "Variables d'environnement:"
    echo "  GITHUB_TOKEN     Token d'accès personnel GitHub"
    echo "  GITHUB_SSH_KEY   Chemin vers la clé SSH privée"
    echo "  GITHUB_AUTH_METHOD  Force la méthode d'authentification (token/ssh/public)"
}

# Fonction de gestion des interruptions
handle_interrupt() {
    log_warning "Interruption détectée (SIGINT/SIGTERM)"
    INTERRUPTED=true
    
    # Sauvegarder l'état actuel si possible
    if [ -n "${total_repos:-}" ] && [ -n "${success_repos:-}" ] && [ -n "${failed_repos:-}" ]; then
        _save_state
    fi
    
    log_info "Arrêt en cours... (Ctrl+C pour forcer l'arrêt)"
    cleanup
    exit 130
}

# Fonction de nettoyage
cleanup() {
    if [ "$QUIET" = false ]; then
        log_info "Nettoyage en cours..."
    fi
    
    # Nettoyer les fichiers temporaires
    local temp_files=(
        "/tmp/git-mirror-*.tmp"
        "/tmp/git-mirror-state-*.json"
        "$SCRIPT_DIR/.git-mirror-temp-*"
    )
    
    for pattern in "${temp_files[@]}"; do
        if ls "$pattern" >/dev/null 2>&1; then
            rm -f "$pattern"
            if [ "$VERBOSE" -ge 2 ]; then
                log_debug "Fichiers temporaires nettoyés: $pattern"
            fi
        fi
    done
    
    # Nettoyer les fichiers d'état si l'exécution s'est bien passée
    if [ -f "$STATE_FILE" ] && [ "$INTERRUPTED" = false ]; then
        rm -f "$STATE_FILE"
        if [ "$VERBOSE" -ge 1 ]; then
            log_info "Fichier d'état nettoyé (exécution réussie)"
        fi
    fi
    
    if [ "$VERBOSE" -ge 1 ]; then
        log_info "Nettoyage terminé"
    fi
}

# Sauvegarder l'état de l'exécution
_save_state() {
    local state_data
    state_data=$(cat <<EOF
{
  "interrupted": $INTERRUPTED,
  "total_repos": $total_repos,
  "success_repos": $success_repos,
  "failed_repos": $failed_repos,
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "context": "$context",
  "username": "$username_or_orgname"
}
EOF
)
    
    echo "$state_data" > "$STATE_FILE" 2>/dev/null || true
}

# Charger l'état de l'exécution
_load_state() {
    if [ -f "$STATE_FILE" ]; then
        if command -v jq >/dev/null 2>&1; then
            total_repos=$(jq -r '.total_repos // 0' "$STATE_FILE")
            success_repos=$(jq -r '.success_repos // 0' "$STATE_FILE")
            failed_repos=$(jq -r '.failed_repos // 0' "$STATE_FILE")
            log_info "État chargé: $success_repos succès, $failed_repos échecs sur $total_repos dépôts"
            return 0
        fi
    fi
    return 1
}

# Vérifier si on doit reprendre
should_resume() {
    if [ "$RESUME" = true ]; then
        if [ -f "$STATE_FILE" ]; then
            local interrupted
            interrupted=$(jq -r '.interrupted' "$STATE_FILE" 2>/dev/null)
            if [ "$interrupted" = "true" ]; then
                log_info "Option --resume activée et état interrompu détecté"
                return 0
            else
                log_warning "Option --resume activée mais aucun état interrompu trouvé"
                return 1
            fi
        else
            log_warning "Option --resume activée mais aucun fichier d'état trouvé"
            return 1
        fi
    fi
    
    # Détection automatique d'un état interrompu
    if [ -f "$STATE_FILE" ]; then
        local interrupted
        interrupted=$(jq -r '.interrupted' "$STATE_FILE" 2>/dev/null)
        if [ "$interrupted" = "true" ]; then
            log_info "État interrompu détecté automatiquement"
            return 0
        fi
    fi
    return 1
}

# Traitement des options avec getopts
parse_options() {
    # Traiter les options combinées comme -vv ou -v -v
    local processed_args=()
    while [[ $# -gt 0 ]]; do
        if [[ "$1" =~ ^-v+$ ]]; then
            # Compter le nombre de v
            local v_count
            v_count=$(grep -o 'v' <<< "$1" | wc -l)
            for ((i=0; i<v_count; i++)); do
                processed_args+=("-v")
            done
        else
            processed_args+=("$1")
        fi
        shift
    done
    
    # Réinitialiser les arguments traités
    set -- "${processed_args[@]}"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--destination)
                DEST_DIR="$2"
                shift 2
                ;;
            -b|--branch)
                BRANCH="$2"
                shift 2
                ;;
            -f|--filter)
                FILTER="$2"
                shift 2
                ;;
            -n|--no-checkout)
                NO_CHECKOUT=true
                shift
                ;;
            -s|--single-branch)
                SINGLE_BRANCH=true
                shift
                ;;
            --depth)
                if [ $# -lt 2 ] || [ -z "$2" ] || [[ "$2" =~ ^- ]]; then
                    log_fatal "L'option --depth nécessite un argument (profondeur)"
                fi
                DEPTH="$2"
                shift 2
                ;;
            --timeout)
                if [ $# -lt 2 ] || [ -z "$2" ] || [[ "$2" =~ ^- ]]; then
                    log_fatal "L'option --timeout nécessite un argument (secondes)"
                fi
                TIMEOUT_CUSTOM="$2"
                shift 2
                ;;
            --parallel)
                if [ $# -lt 2 ] || [ -z "$2" ] || [[ "$2" =~ ^- ]]; then
                    log_fatal "L'option --parallel nécessite un argument (nombre de jobs)"
                fi
                PARALLEL_JOBS="$2"
                PARALLEL_ENABLED=true  # Activer la parallélisation
                shift 2
                ;;
            --resume)
                RESUME=true
                shift
                ;;
            --incremental)
                INCREMENTAL=true
                shift
                ;;
            --exclude)
                if [ $# -lt 2 ] || [ -z "$2" ] || [[ "$2" =~ ^- ]]; then
                    log_fatal "L'option --exclude nécessite un argument (pattern)"
                fi
                EXCLUDE_PATTERNS+=("$2")
                shift 2
                ;;
            --exclude-file)
                if [ $# -lt 2 ] || [ -z "$2" ] || [[ "$2" =~ ^- ]]; then
                    log_fatal "L'option --exclude-file nécessite un argument (fichier)"
                fi
                export EXCLUDE_FILE="$2"
                shift 2
                ;;
            --include)
                if [ $# -lt 2 ] || [ -z "$2" ] || [[ "$2" =~ ^- ]]; then
                    log_fatal "L'option --include nécessite un argument (pattern)"
                fi
                INCLUDE_PATTERNS+=("$2")
                shift 2
                ;;
            --include-file)
                if [ $# -lt 2 ] || [ -z "$2" ] || [[ "$2" =~ ^- ]]; then
                    log_fatal "L'option --include-file nécessite un argument (fichier)"
                fi
                export INCLUDE_FILE="$2"
                shift 2
                ;;
            --metrics)
                if [ $# -lt 2 ] || [ -z "$2" ] || [[ "$2" =~ ^- ]]; then
                    log_fatal "L'option --metrics nécessite un argument (fichier)"
                fi
                METRICS_FILE="$2"
                METRICS_ENABLED=true
                shift 2
                ;;
            --interactive)
                export INTERACTIVE_MODE=true
                shift
                ;;
            --confirm)
                export CONFIRM_MODE=true
                shift
                ;;
            --yes|-y)
                export AUTO_YES=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=$((VERBOSE + 1))
                shift
                ;;
            -q|--quiet)
                QUIET=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --profile)
                PROFILING_ENABLED=true
                shift
                ;;
            --skip-count)
                SKIP_COUNT=true
                shift
                ;;
            --no-cache)
                NO_CACHE=true
                shift
                ;;
            --repo-type)
                if [ $# -lt 2 ] || [ -z "$2" ] || [[ "$2" =~ ^- ]]; then
                    log_fatal "L'option --repo-type nécessite un argument (all, public, private)"
                fi
                REPO_TYPE="$2"
                case "$REPO_TYPE" in
                    all|public|private)
                        ;;
                    *)
                        log_fatal "Type de dépôt invalide: $REPO_TYPE (options: all, public, private)"
                        ;;
                esac
                shift 2
                ;;
            --exclude-forks)
                EXCLUDE_FORKS=true
                shift
                ;;
            --multi-sources)
                if [ $# -lt 2 ] || [ -z "$2" ] || [[ "$2" =~ ^- ]]; then
                    log_fatal "L'option --multi-sources nécessite un argument (format: users:u1,u2 orgs:o1,o2)"
                fi
                MULTI_SOURCES="$2"
                MULTI_SOURCES_ENABLED=true
                shift 2
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            -*)
                echo "Option inconnue: $1" >&2
                show_help
                exit 1
                ;;
            *)
                # Arguments positionnels
                if [ -z "$context" ]; then
                    context="$1"
                elif [ -z "$username_or_orgname" ]; then
                    username_or_orgname="$1"
                else
                    echo "Trop d'arguments positionnels" >&2
                    show_help
	exit 1
fi
                shift
                ;;
        esac
    done
}

# Vérifier les dépendances
check_dependencies() {
    # Vérifier git
    if ! command -v git >/dev/null 2>&1; then
        log_error "Git n'est pas installé"
        return 1
    fi
    
    # Vérifier jq
    if ! command -v jq >/dev/null 2>&1; then
        log_error "jq n'est pas installé"
        return 1
    fi
    
    # Vérifier curl
    if ! command -v curl >/dev/null 2>&1; then
        log_error "curl n'est pas installé"
        return 1
    fi
    
    log_debug "Toutes les dépendances sont installées"
    return 0
}

# Fonction principale
main() {
    # Configuration des signaux
    trap handle_interrupt SIGINT SIGTERM
    
    # Initialiser les modules
    init_logger "$VERBOSE" "$QUIET" "$DRY_RUN" true
    init_config
    
    # Activer le profiling si demandé
    if [ "${PROFILING_ENABLED:-false}" = "true" ]; then
        profiling_enable
    fi
    
    # Nettoyer le token GitHub s'il existe (supprimer les espaces et newlines)
    if [ -n "${GITHUB_TOKEN:-}" ]; then
        local cleaned_token
        cleaned_token=$(echo "$GITHUB_TOKEN" | tr -d '[:space:]')
        export GITHUB_TOKEN="$cleaned_token"
        log_debug "Token GitHub nettoyé (longueur: ${#GITHUB_TOKEN})"
    fi
    
    # Tentative d'obtention automatique du token via gh si non défini
    if [ -z "${GITHUB_TOKEN:-}" ] && command -v gh >/dev/null 2>&1; then
        local gh_token
        if gh_token=$(gh auth token 2>/dev/null) && [ -n "$gh_token" ]; then
            local cleaned_token
            cleaned_token=$(echo "$gh_token" | tr -d '[:space:]')
            export GITHUB_TOKEN="$cleaned_token"
            log_debug "Token GitHub obtenu automatiquement via 'gh auth token' (longueur: ${#GITHUB_TOKEN})"
        fi
    fi
    
    if [ -n "${GITHUB_TOKEN:-}" ]; then
        log_debug "Token GitHub final: présent (longueur: ${#GITHUB_TOKEN})"
    else
        log_debug "Token GitHub final: absent"
    fi
    
    # Initialiser l'authentification
    if ! auth_setup; then
        log_error "Échec de l'initialisation de l'authentification"
        exit 1
    fi
    
    # Initialiser l'API GitHub (passer l'option --no-cache si activée)
    if [ "$NO_CACHE" = true ]; then
        export API_CACHE_DISABLED=true
        log_info "Mode --no-cache activé: le cache API sera ignoré"
    fi
    
    if ! api_setup; then
        log_error "Échec de l'initialisation de l'API GitHub"
        exit 1
    fi
    
    # Initialiser la validation
    if ! validate_setup; then
        log_error "Échec de l'initialisation de la validation"
        exit 1
    fi
    
    # Initialiser les opérations Git
    if ! git_ops_setup; then
        log_error "Échec de l'initialisation des opérations Git"
        exit 1
    fi
    
    # Initialiser le cache
    if ! cache_setup; then
        log_error "Échec de l'initialisation du cache"
        exit 1
    fi
    
    # Initialiser la parallélisation
    if ! parallel_setup; then
        log_error "Échec de l'initialisation de la parallélisation"
        exit 1
    fi
    
    # Initialiser le filtrage
    if ! filters_setup; then
        log_error "Échec de l'initialisation du filtrage"
        exit 1
    fi
    
    # Initialiser les métriques
    if ! metrics_setup; then
        log_error "Échec de l'initialisation des métriques"
        exit 1
    fi
    
    # Initialiser l'interface interactive
    if ! interactive_setup; then
        log_error "Échec de l'initialisation de l'interface interactive"
        exit 1
    fi
    
    # Initialiser la gestion d'état
    if ! state_setup; then
        log_error "Échec de l'initialisation de la gestion d'état"
        exit 1
    fi
    
    # Initialiser le mode incrémental
    if ! incremental_setup; then
        log_error "Échec de l'initialisation du mode incrémental"
        exit 1
    fi
    
    # Activer le profiling si demandé
    if [ "$PROFILING_ENABLED" = "true" ]; then
        profiling_enable
    fi
    
    # Vérifier les dépendances
    check_dependencies
    
    # Afficher la configuration
    if [ "$QUIET" = false ]; then
        get_config
    fi
    
    # Mode dry-run
    if [ "$DRY_RUN" = true ]; then
        log_dry_run "=== MODE DRY-RUN ACTIVÉ ==="
        log_dry_run "Aucune action réelle ne sera effectuée"
        log_dry_run "================================"
    fi
    
    log_info "Début du processus de synchronisation Git Mirror"
    log_info "Cible: $context/$username_or_orgname"
    
    # Vérifier si on doit reprendre
    if should_resume; then
        if _load_state; then
            log_info "Reprise de l'exécution interrompue"
        else
            log_warning "Impossible de charger l'état, démarrage normal"
        fi
    fi
    
    # Calculer le nombre total de dépôts
    if [ "$SKIP_COUNT" = true ]; then
        log_info "Calcul du nombre total de dépôts ignoré (--skip-count activé)"
        total_repos=100  # Estimation par défaut
    else
        log_info "Calcul du nombre total de dépôts..."
        
        if [ "$total_repos" -eq 0 ]; then
            total_repos=$(api_get_total_repos "$context" "$username_or_orgname")
            
            # Vérifier que total_repos est un nombre valide
            log_debug "Valeur totale reçue: '$total_repos' (longueur: ${#total_repos})"
            if ! [[ "$total_repos" =~ ^[0-9]+$ ]]; then
                log_error "Nombre de dépôts invalide: '$total_repos'"
                exit 1
            fi
            
            if [ "$total_repos" -eq 0 ]; then
                log_warning "Aucun dépôt trouvé ou limite de taux API atteinte pour $context/$username_or_orgname"
                log_info "Utilisation d'une estimation par défaut (100 repos)"
                total_repos=100  # Estimation par défaut
            fi
            
            # Mettre en cache le nombre total
            cache_set_total_repos "$context" "$username_or_orgname" "$total_repos"
        fi
    fi
    
    log_info "Nombre total de dépôts à traiter: $total_repos"
    
    # Demander confirmation avant de commencer
    local estimated_space
    estimated_space=$((total_repos * 50))  # 50MB par repo
    
    if ! interactive_confirm_start "$context" "$username_or_orgname" "$DEST_DIR" "$total_repos" "$estimated_space" "$PARALLEL_JOBS" "$FILTER_ENABLED" "$INCREMENTAL_ENABLED" "$GITHUB_AUTH_METHOD"; then
        log_info "Opération annulée par l'utilisateur"
        exit 0
    fi
    
    # Vérifier l'espace disque
    if [ "$DRY_RUN" = false ]; then
        log_info "Espace estimé requis: ${estimated_space}MB"
    else
        log_dry_run "Vérification de l'espace disque (simulation)"
    fi
    
    # Créer le répertoire de destination et convertir en chemin absolu
    if [ "$DRY_RUN" = false ]; then
        if ! mkdir -p "$DEST_DIR"; then
            log_fatal "Impossible de créer le répertoire de destination: $DEST_DIR"
        fi
        
        # Convertir DEST_DIR en chemin absolu pour éviter les problèmes en mode parallel
        # Les sous-processus peuvent changer de répertoire courant
        if [ -d "$DEST_DIR" ]; then
            DEST_DIR=$(cd "$DEST_DIR" && pwd)
            log_debug "Répertoire de destination (absolu): $DEST_DIR"
        fi
    else
        log_dry_run "Création du répertoire de destination: $DEST_DIR"
    fi
    
    # Traitement des dépôts (api_fetch_all_repos récupère TOUTES les pages d'un coup)
    log_info "Récupération des dépôts..."
    
    local repos_json
    repos_json=$(api_fetch_all_repos "$context" "$username_or_orgname")
    
    local api_exit_code=$?
    
    if [ $api_exit_code -ne 0 ]; then
        log_error "Échec de la récupération des dépôts (code: $api_exit_code)"
        exit 1
    fi
    
    if [ -z "$repos_json" ]; then
        log_error "Réponse API vide"
        exit 1
    fi
    
    # Vérifier que c'est un array JSON valide
    if ! echo "$repos_json" | jq -e 'type == "array"' >/dev/null 2>&1; then
        log_error "Réponse API invalide"
        exit 1
    fi
    
    # Mettre à jour le nombre total de dépôts avec le nombre réel récupéré
    local actual_repos_count
    actual_repos_count=$(echo "$repos_json" | jq 'length')
    if [ "$actual_repos_count" -gt 0 ]; then
        total_repos=$actual_repos_count
        log_debug "Nombre réel de dépôts récupérés: $total_repos"
    fi
    
    # En mode incrémental, filtrer les dépôts modifiés
    local repos_to_process
    if [ "$INCREMENTAL" = true ]; then
        local last_sync
        last_sync=$(cache_get_last_sync "$context" "$username_or_orgname")
        repos_to_process=$(echo "$repos_json" | jq -r --arg last_sync "$last_sync" '
            .[] | select(.pushed_at > $last_sync) | .clone_url
        ')
        
        local filtered_count
        filtered_count=$(echo "$repos_to_process" | wc -l)
        log_info "Mode incrémental: $filtered_count dépôts modifiés depuis $last_sync"
    else
        # Filtrer les forks si --exclude-forks est activé
        if [ "$EXCLUDE_FORKS" = true ]; then
            repos_to_process=$(echo "$repos_json" | jq -r '.[] | select(.fork == false) | .clone_url')
            local forks_excluded
            forks_excluded=$(echo "$repos_json" | jq '[.[] | select(.fork == true)] | length')
            log_info "Mode exclude-forks: $forks_excluded dépôts forké exclus"
        else
            repos_to_process=$(echo "$repos_json" | jq -r '.[].clone_url')
        fi
    fi
    
    # Traiter les dépôts (séquentiel ou parallèle)
    if [ "$PARALLEL_ENABLED" = "true" ] && [ "$PARALLEL_JOBS" -gt 1 ] && [ "$DRY_RUN" = false ]; then
        # Mode parallèle avec GNU parallel
        log_info "Traitement parallèle de $(echo "$repos_to_process" | wc -l) dépôts avec $PARALLEL_JOBS jobs"
        
        # Initialiser toutes les variables avant le wrapper pour éviter "empty string"
        # Note: DEST_DIR a déjà été converti en chemin absolu plus haut
        BRANCH="${BRANCH:-}"
        DEPTH="${DEPTH:-1}"
        FILTER="${FILTER:-}"
        SINGLE_BRANCH="${SINGLE_BRANCH:-false}"
        NO_CHECKOUT="${NO_CHECKOUT:-false}"
        GITHUB_AUTH_METHOD="${GITHUB_AUTH_METHOD:-public}"
        
        # Créer une fonction wrapper pour parallel
        _process_repo_wrapper() {
            # Variables d'environnement héritées de l'environnement parent
            local filter_enabled="${FILTER_ENABLED:-false}"
            local github_auth="${GITHUB_AUTH_METHOD:-public}"
            
            local repo_url="$1"
            local repo_name
            repo_name=$(basename "$repo_url" .git)
            local repo_full_name
            repo_full_name=$(echo "$repo_url" | sed 's|https://github.com/||' | sed 's|.git||')
            
            # Vérifier le filtrage
            if [ "$filter_enabled" = "true" ] && ! filters_should_process "$repo_name" "$repo_full_name"; then
                echo "FILTERED:$repo_name"
                return 0
            fi
            
            # Transformer l'URL selon la méthode d'authentification
            local final_url
            if [ "$github_auth" = "ssh" ]; then
                final_url=$(auth_transform_url "$repo_url" "ssh")
            else
                final_url="$repo_url"
            fi
            
            local repo_path="$DEST_DIR/$repo_name"
            
            if repository_exists "$repo_path"; then
                if update_repository "$repo_path" "$BRANCH"; then
                    echo "SUCCESS:$repo_name"
                else
                    echo "FAILED:$repo_name"
                fi
            else
                if clone_repository "$final_url" "$DEST_DIR" "$BRANCH" "$DEPTH" "$FILTER" "$SINGLE_BRANCH" "$NO_CHECKOUT"; then
                    echo "SUCCESS:$repo_name"
                else
                    echo "FAILED:$repo_name"
                fi
            fi
        }
        
        export -f _process_repo_wrapper repository_exists update_repository clone_repository
        export -f auth_transform_url filters_should_process log_info log_success log_error log_debug _log_message
        export -f _execute_git_command _configure_safe_directory _update_submodules _update_branch
        export DEST_DIR="${DEST_DIR:-./repositories}" BRANCH DEPTH FILTER SINGLE_BRANCH NO_CHECKOUT GITHUB_AUTH_METHOD VERBOSE_LEVEL QUIET_MODE
        export FILTER_ENABLED=${FILTER_ENABLED:-false}
        export DRY_RUN=${DRY_RUN:-false}
        
        # Exécuter en parallèle
        parallel_results=$(echo "$repos_to_process" | parallel -j "$PARALLEL_JOBS" --timeout "$PARALLEL_TIMEOUT" _process_repo_wrapper {})
        
        # Compter les succès et échecs de manière sécurisée
        local temp_success temp_failed
        temp_success=$(echo "$parallel_results" | grep -c "SUCCESS:" 2>/dev/null || echo "0")
        temp_failed=$(echo "$parallel_results" | grep -c "FAILED:" 2>/dev/null || echo "0")
        
        success_from_parallel=$(echo "$temp_success" | tr -d '\n\r ')
        failed_from_parallel=$(echo "$temp_failed" | tr -d '\n\r ')
        
        # Valeurs par défaut si vides
        success_from_parallel=${success_from_parallel:-0}
        failed_from_parallel=${failed_from_parallel:-0}
        
        success_repos=$((success_repos + success_from_parallel))
        failed_repos=$((failed_repos + failed_from_parallel))
        counter=$((counter + success_from_parallel + failed_from_parallel))
    else
        # Mode séquentiel (par défaut ou dry-run)
        while IFS= read -r repo_url; do
            if [ -n "$repo_url" ] && [ "$repo_url" != "null" ]; then
                local repo_name
                repo_name=$(basename "$repo_url" .git)
                local repo_full_name
                repo_full_name=$(echo "$repo_url" | sed 's|https://github.com/||' | sed 's|.git||')
                
                # Vérifier le filtrage
                if [ "$FILTER_ENABLED" = "true" ] && ! filters_should_process "$repo_name" "$repo_full_name"; then
                    log_debug "Dépôt filtré: $repo_name"
                    counter=$((counter + 1))
                    continue
                fi
                
                log_info "Traitement du dépôt $counter/$total_repos: $repo_name"
                
                # Transformer l'URL selon la méthode d'authentification
                local final_url
                if [ "$GITHUB_AUTH_METHOD" = "ssh" ]; then
                    final_url=$(auth_transform_url "$repo_url" "ssh")
                else
                    final_url="$repo_url"
                fi
                
                if [ "$DRY_RUN" = true ]; then
                    log_dry_run "Clonage du dépôt: $repo_name dans $DEST_DIR/$repo_name"
                    log_dry_run "  Commande qui serait exécutée:"
                    log_dry_run "    - git clone [options] $final_url"
                    success_repos=$((success_repos + 1))
                else
                    local repo_path="$DEST_DIR/$repo_name"
                    
                    if repository_exists "$repo_path"; then
                        if update_repository "$repo_path" "$BRANCH"; then
                            success_repos=$((success_repos + 1))
                        else
                            failed_repos=$((failed_repos + 1))
                            log_error "Échec de la mise à jour: $repo_name"
                        fi
                    else
                        if clone_repository "$final_url" "$DEST_DIR" "$BRANCH" "$DEPTH" "$FILTER" "$SINGLE_BRANCH" "$NO_CHECKOUT"; then
                            success_repos=$((success_repos + 1))
                        else
                            failed_repos=$((failed_repos + 1))
                            log_error "Échec du clonage: $repo_name"
                        fi
                    fi
                fi
                
                counter=$((counter + 1))
                
                # Sauvegarder l'état tous les 10 dépôts traités
                if [ $((counter % 10)) -eq 0 ]; then
                    _save_state
                fi
            fi
        done <<< "$repos_to_process"
    fi
    
    # Résumé final
    log_info "=== Résumé de la synchronisation ==="
    log_success "Dépôts traités avec succès: $success_repos"
    if [ "$failed_repos" -gt 0 ]; then
        log_warning "Dépôts en échec: $failed_repos"
    fi
    log_info "Total traité: $((success_repos + failed_repos))/$total_repos"
    
    # Mettre à jour le timestamp de synchronisation en mode incrémental
    if [ "$INCREMENTAL" = true ] && [ "$failed_repos" -eq 0 ]; then
        cache_set_last_sync "$context" "$username_or_orgname"
    fi
    
    # Afficher les statistiques des modules
    if [ "$VERBOSE" -ge 2 ]; then
        echo ""
        # Afficher les statistiques API si disponibles
        if command -v api_get_stats >/dev/null 2>&1; then
            api_get_stats
        fi
        echo ""
        get_git_stats
        echo ""
        get_cache_stats
        echo ""
        get_parallel_stats
        echo ""
        get_filter_stats
        echo ""
        get_interactive_stats
    fi
    
    # Afficher le résumé de profiling si activé
    if [ "${PROFILING_ENABLED:-false}" = "true" ]; then
        echo ""
        profiling_summary
    fi
    
    # Exporter les métriques
    if [ "$METRICS_ENABLED" = true ]; then
        export_metrics "$METRICS_FILE" "json"
    fi
    
    # Nettoyage final
    cleanup
    parallel_cleanup
    
    if [ "$failed_repos" -gt 0 ]; then
        exit 1
    else
        exit 0
    fi
}

# Point d'entrée principal
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Vérifier si --help est demandé
    if [[ "$*" =~ --help ]] || [[ "$*" =~ -h ]]; then
        show_help
        exit 0
    fi
    
    # Vérifier les arguments
    if [ $# -lt 2 ]; then
        echo "Usage: $0 [OPTIONS] context username_or_orgname" >&2
        echo "Utilisez '$0 --help' pour plus d'informations" >&2
        exit 1
    fi
    
    # Parser les options
    parse_options "$@"
    
    # Initialiser le logger pour les messages d'erreur
    init_logger "$VERBOSE" "$QUIET" "$DRY_RUN" true
    
    # Gérer le mode multi-sources
    if [ "$MULTI_SOURCES_ENABLED" = true ]; then
        if ! multi_validate_sources "$MULTI_SOURCES"; then
            log_error "Validation des sources multiples échouée"
            exit 1
        fi
        # Traiter les sources multiples
        multi_process_sources "$MULTI_SOURCES" "$0" "${@:1}"
        exit 0
    fi
    
    # Valider les arguments
    if [ -z "$context" ] || [ -z "$username_or_orgname" ]; then
        echo "Arguments manquants: context et username_or_orgname requis" >&2
        show_help
        exit 1
    fi
    
    # Valider la configuration
    if ! validate_all_params "$context" "$username_or_orgname" "$DEST_DIR" "$BRANCH" "$FILTER" "$DEPTH" "$PARALLEL_JOBS" "$TIMEOUT_CUSTOM"; then
        log_error "Validation des paramètres échouée"
        exit 1
    fi
    
    # Exécuter le script principal
    main "$@"
fi
