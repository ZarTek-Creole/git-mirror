#!/bin/bash

# Configuration de sécurité Bash
set -euo pipefail

# coverage-report.sh - Script de génération de rapport de coverage avec kcov
# Auteur: ZarTek-Creole
# Date: 2025-01-29

# Couleurs pour l'affichage
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Configuration par défaut
readonly SCRIPT_DIR
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
readonly COVERAGE_DIR="${SCRIPT_DIR}/coverage"
readonly COVERAGE_HTML_DIR="${COVERAGE_DIR}/html"
readonly COVERAGE_JSON_FILE="${COVERAGE_DIR}/report.json"
readonly KCOV_VERSION="v38"
readonly COVERAGE_THRESHOLD=80

# Variables d'état
KCOV_AVAILABLE=false
export KCOV_AVAILABLE
SHELLSPEC_AVAILABLE=false
export SHELLSPEC_AVAILABLE

# Fonctions d'affichage
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

# Fonction d'aide
show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Génère un rapport de coverage du code avec kcov et ShellSpec.

Options:
  -h, --help          Afficher cette aide
  -c, --clean         Nettoyer les fichiers de coverage précédents
  -t, --threshold NUM Seuil de coverage minimum (défaut: 80)
  --no-open           Ne pas ouvrir le rapport HTML automatiquement
  --force             Forcer la réinstallation de ShellSpec et kcov

Exemples:
  $0                  Générer le rapport de coverage
  $0 -c               Nettoyer et régénérer
  $0 -t 90            Définir le seuil à 90%
EOF
}

# Vérifier si une commande existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Installer ShellSpec
install_shellspec() {
    log_info "Installation de ShellSpec..."
    
    local shellspec_path="${SCRIPT_DIR}/bin/shellspec"
    
    # Vérifier si déjà installé
    if [ -x "$shellspec_path" ] && [ "${FORCE_INSTALL:-false}" != "true" ]; then
        log_success "ShellSpec déjà installé"
        SHELLSPEC_AVAILABLE=true
        return 0
    fi
    
    # Installer ShellSpec
    cd "$SCRIPT_DIR" || exit 1
    if curl -fsSL https://git.io/shellspec | sh -s -- --yes; then
        log_success "ShellSpec installé avec succès"
        SHELLSPEC_AVAILABLE=true
        export PATH="${SCRIPT_DIR}/bin:${PATH}"
    else
        log_error "Échec de l'installation de ShellSpec"
        return 1
    fi
}

# Installer kcov
install_kcov() {
    log_info "Installation de kcov v${KCOV_VERSION}..."
    
    # Vérifier si déjà installé
    if command_exists kcov; then
        local current_version
        current_version=$(kcov --version 2>&1 | grep -oP 'kcov \K\d+' || echo "0")
        if [ "${FORCE_INSTALL:-false}" != "true" ]; then
            log_success "kcov déjà installé (version $current_version)"
            KCOV_AVAILABLE=true
            return 0
        fi
    fi
    
    # Installation des dépendances
    log_info "Installation des dépendances..."
    
    if command_exists apt-get; then
        sudo apt-get update -qq
        sudo apt-get install -y -qq \
            libcurl4-openssl-dev \
            libelf-dev \
            libdw-dev \
            cmake \
            gcc \
            binutils-dev \
            libiberty-dev \
            build-essential
    elif command_exists brew; then
        brew install cmake zlib libcurl
    else
        log_error "Gestionnaire de paquets non supporté (apt-get ou brew requis)"
        return 1
    fi
    
    # Télécharger et compiler kcov
    local kcov_dir="/tmp/kcov-${KCOV_VERSION}"
    
    if [ ! -d "$kcov_dir" ] || [ "${FORCE_INSTALL:-false}" = "true" ]; then
        rm -rf "$kcov_dir"
        
        log_info "Téléchargement de kcov ${KCOV_VERSION}..."
        cd /tmp || exit 1
        
        if ! wget -q "https://github.com/SimonKagstrom/kcov/archive/${KCOV_VERSION}.tar.gz"; then
            log_error "Échec du téléchargement de kcov"
            return 1
        fi
        
        tar -xzf "${KCOV_VERSION}.tar.gz"
    fi
    
    log_info "Compilation de kcov..."
    cd "$kcov_dir" || exit 1
    mkdir -p build
    cd build || exit 1
    
    if cmake .. && make -j"$(nproc 2>/dev/null || echo 4)"; then
        sudo make install
        log_success "kcov installé avec succès"
        KCOV_AVAILABLE=true
        cd /tmp && rm -rf "kcov-${KCOV_VERSION}" "${KCOV_VERSION}.tar.gz"
    else
        log_error "Échec de la compilation de kcov"
        return 1
    fi
}

# Nettoyer les fichiers de coverage
clean_coverage() {
    log_info "Nettoyage des fichiers de coverage..."
    rm -rf "$COVERAGE_DIR"
    mkdir -p "$COVERAGE_DIR"
    log_success "Fichiers de coverage nettoyés"
}

# Générer le rapport de coverage
generate_coverage() {
    log_info "Génération du rapport de coverage..."
    
    # Créer les répertoires nécessaires
    mkdir -p "$COVERAGE_HTML_DIR"
    
    # Options kcov
    local kcov_options=(
        "--include-pattern=lib/"
        "--exclude-pattern=test"
        "--exclude-path=/usr,/sys,/proc,/dev,/tmp"
        "--html"
        "--merge"
        "$COVERAGE_HTML_DIR"
    )
    
    # Exécuter les tests avec kcov
    if [ "$SHELLSPEC_AVAILABLE" = true ]; then
        log_info "Exécution des tests ShellSpec avec coverage..."
        
        # Exporter PATH pour trouver shellspec
        export PATH="${SCRIPT_DIR}/bin:${PATH}"
        
        # Exécuter shellspec avec kcov
        if shellspec --init >/dev/null 2>&1; then
            shellspec --kcov --kcov-options="${kcov_options[*]}" \
                --no-banner \
                --quiet \
                tests/spec/ || true
        fi
    else
        log_warning "ShellSpec non disponible, tentative d'installation..."
        install_shellspec || {
            log_error "Impossible de générer le coverage sans ShellSpec"
            return 1
        }
        
        shellspec --kcov --kcov-options="${kcov_options[*]}" \
            --no-banner \
            --quiet \
            tests/spec/ || true
    fi
    
    # Générer un résumé JSON simple
    generate_coverage_summary
    
    log_success "Rapport de coverage généré dans ${COVERAGE_HTML_DIR}"
}

# Générer un résumé JSON
generate_coverage_summary() {
    local coverage_percent=0
    local total_lines=0
    local covered_lines=0
    
    # Calculer le coverage (simplifié)
    if [ -f "${COVERAGE_HTML_DIR}/index.html" ]; then
        # Lire le pourcentage depuis le HTML si disponible
        coverage_percent=$(grep -oP 'coverage.*?\K\d+' "${COVERAGE_HTML_DIR}/index.html" 2>/dev/null | head -1 || echo "0")
    fi
    
    # Générer le JSON
    cat > "$COVERAGE_JSON_FILE" << EOF
{
  "coverage_percent": ${coverage_percent},
  "total_lines": ${total_lines},
  "covered_lines": ${covered_lines},
  "threshold": ${COVERAGE_THRESHOLD},
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
    
    log_info "Résumé JSON généré: ${COVERAGE_JSON_FILE}"
}

# Afficher le résumé
show_summary() {
    local coverage_percent="${1:-0}"
    local threshold="${2:-$COVERAGE_THRESHOLD}"
    
    echo ""
    echo "═══════════════════════════════════════════════"
    echo "  📊 Rapport de Coverage"
    echo "═══════════════════════════════════════════════"
    echo "  Coverage: ${coverage_percent}%"
    echo "  Seuil: ${threshold}%"
    echo "  HTML: ${COVERAGE_HTML_DIR}/index.html"
    echo "  JSON: ${COVERAGE_JSON_FILE}"
    echo "═══════════════════════════════════════════════"
    
    if (( $(echo "$coverage_percent < $threshold" | bc -l 2>/dev/null || echo "1") )); then
        log_warning "Coverage en dessous du seuil minimum"
        return 1
    else
        log_success "Coverage acceptable"
        return 0
    fi
}

# Ouvrir le rapport HTML
open_report() {
    local report_file="${COVERAGE_HTML_DIR}/index.html"
    
    if [ ! -f "$report_file" ]; then
        log_warning "Aucun rapport HTML trouvé"
        return 1
    fi
    
    log_info "Ouverture du rapport HTML..."
    
    if command_exists xdg-open; then
        xdg-open "$report_file"
    elif command_exists open; then
        open "$report_file"
    else
        log_info "Ouvert le navigateur avec: file://${report_file}"
    fi
}

# Fonction principale
main() {
    local do_clean=false
    local open_html=true
    local custom_threshold="${COVERAGE_THRESHOLD:-80}"
    
    # Parser les arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -c|--clean)
                do_clean=true
                shift
                ;;
            -t|--threshold)
                custom_threshold="$2"
                shift 2
                ;;
            --no-open)
                open_html=false
                shift
                ;;
            --force)
                export FORCE_INSTALL=true
                shift
                ;;
            *)
                log_error "Option inconnue: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Démarrer
    echo ""
    log_info "=== Génération du rapport de coverage ==="
    echo ""
    
    # Nettoyer si demandé
    if [ "$do_clean" = true ]; then
        clean_coverage
    fi
    
    # Vérifier et installer les dépendances
    if ! command_exists kcov; then
        install_kcov || {
            log_error "Impossible d'installer kcov"
            exit 1
        }
    else
        KCOV_AVAILABLE=true
    fi
    
    if [ ! -x "${SCRIPT_DIR}/bin/shellspec" ]; then
        install_shellspec || {
            log_error "Impossible d'installer ShellSpec"
            exit 1
        }
    else
        SHELLSPEC_AVAILABLE=true
    fi
    
    # Générer le coverage
    generate_coverage
    
    # Afficher le résumé
    local coverage_percent=0
    if [ -f "$COVERAGE_JSON_FILE" ]; then
        coverage_percent=$(jq -r '.coverage_percent' "$COVERAGE_JSON_FILE" 2>/dev/null || echo "0")
    fi
    
    show_summary "$coverage_percent" "$custom_threshold"
    local exit_code=$?
    
    # Ouvrir le rapport HTML
    if [ "$open_html" = true ] && [ "$exit_code" = 0 ]; then
        open_report
    fi
    
    echo ""
    exit $exit_code
}

# Exécuter main si le script est appelé directement
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi

