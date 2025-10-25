#!/bin/bash
# install.sh - Script d'installation de git-mirror
# Installe git-mirror et ses dépendances sur le système

set -euo pipefail

# Variables de configuration
PREFIX="${PREFIX:-/usr/local}"
BINDIR="${BINDIR:-$PREFIX/bin}"
MANDIR="${MANDIR:-$PREFIX/share/man/man1}"
CONFDIR="${CONFDIR:-/etc/git-mirror}"
VERSION="2.0.0"

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction d'affichage des messages
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Fonction d'aide
show_help() {
    cat << EOF
Script d'installation de git-mirror

Usage: $0 [OPTIONS]

Options:
    -h, --help          Afficher cette aide
    -p, --prefix DIR    Préfixe d'installation (défaut: $PREFIX)
    -b, --bindir DIR    Répertoire des binaires (défaut: $BINDIR)
    -m, --mandir DIR    Répertoire des pages man (défaut: $MANDIR)
    -c, --confdir DIR   Répertoire de configuration (défaut: $CONFDIR)
    -d, --deps          Installer les dépendances
    -t, --test          Exécuter les tests après installation
    -f, --force         Forcer l'installation même si déjà installé
    -u, --uninstall     Désinstaller git-mirror

Exemples:
    $0                          # Installation standard
    $0 --deps --test            # Installation avec dépendances et tests
    $0 --prefix /opt/git-mirror # Installation dans un répertoire personnalisé
    $0 --uninstall              # Désinstallation

EOF
}

# Vérifier si git-mirror est déjà installé
check_installed() {
    if command -v git-mirror >/dev/null 2>&1; then
        local installed_version
        installed_version=$(git-mirror --version 2>/dev/null || echo "unknown")
        log_warning "git-mirror est déjà installé (version: $installed_version)"
        return 0
    else
        return 1
    fi
}

# Installer les dépendances
install_dependencies() {
    log_info "Installation des dépendances..."
    
    if command -v apt-get >/dev/null 2>&1; then
        log_info "Détection d'un système Debian/Ubuntu"
        sudo apt-get update
        sudo apt-get install -y jq parallel git curl bash
    elif command -v yum >/dev/null 2>&1; then
        log_info "Détection d'un système Red Hat/CentOS"
        sudo yum install -y jq parallel git curl bash
    elif command -v dnf >/dev/null 2>&1; then
        log_info "Détection d'un système Fedora"
        sudo dnf install -y jq parallel git curl bash
    elif command -v brew >/dev/null 2>&1; then
        log_info "Détection d'un système macOS"
        brew install jq parallel git curl bash
    elif command -v pacman >/dev/null 2>&1; then
        log_info "Détection d'un système Arch Linux"
        sudo pacman -S jq parallel git curl bash
    else
        log_error "Système d'exploitation non supporté"
        log_info "Veuillez installer manuellement: jq, parallel, git, curl, bash"
        return 1
    fi
    
    log_success "Dépendances installées avec succès"
}

# Installer git-mirror
install_git_mirror() {
    log_info "Installation de git-mirror..."
    
    # Créer les répertoires nécessaires
    sudo mkdir -p "$BINDIR" "$MANDIR" "$CONFDIR"
    
    # Installer le script principal
    sudo cp git-mirror.sh "$BINDIR/git-mirror"
    sudo chmod +x "$BINDIR/git-mirror"
    
    # Installer la configuration
    sudo cp config/git-mirror.conf "$CONFDIR/"
    
    # Installer la page man si disponible
    if [ -f docs/git-mirror.1 ]; then
        sudo cp docs/git-mirror.1 "$MANDIR/"
        log_success "Page man installée"
    fi
    
    # Créer un lien symbolique si nécessaire
    if [ "$BINDIR" != "/usr/local/bin" ] && [ ! -L /usr/local/bin/git-mirror ]; then
        sudo ln -sf "$BINDIR/git-mirror" /usr/local/bin/git-mirror
    fi
    
    log_success "git-mirror installé dans $BINDIR/git-mirror"
}

# Exécuter les tests
run_tests() {
    log_info "Exécution des tests..."
    
    if [ -f Makefile ]; then
        make test
    else
        log_warning "Makefile non trouvé, exécution des tests manuels"
        
        # Test shellcheck
        if command -v shellcheck >/dev/null 2>&1; then
            shellcheck git-mirror.sh lib/*/*.sh config/*.sh
            log_success "ShellCheck: Aucun problème détecté"
        fi
        
        # Test bats
        if command -v bats >/dev/null 2>&1; then
            bats tests/
            log_success "Tests unitaires: Tous passés"
        fi
    fi
}

# Désinstaller git-mirror
uninstall_git_mirror() {
    log_info "Désinstallation de git-mirror..."
    
    # Supprimer les fichiers
    sudo rm -f "$BINDIR/git-mirror"
    sudo rm -f "$CONFDIR/git-mirror.conf"
    sudo rm -f "$MANDIR/git-mirror.1"
    sudo rm -f /usr/local/bin/git-mirror
    
    # Supprimer les répertoires vides
    sudo rmdir "$CONFDIR" 2>/dev/null || true
    
    log_success "git-mirror désinstallé avec succès"
}

# Fonction principale
main() {
    local install_deps=false
    local run_tests_after=false
    local force_install=false
    local uninstall_mode=false
    
    # Parser les arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -p|--prefix)
                PREFIX="$2"
                BINDIR="$PREFIX/bin"
                MANDIR="$PREFIX/share/man/man1"
                shift 2
                ;;
            -b|--bindir)
                BINDIR="$2"
                shift 2
                ;;
            -m|--mandir)
                MANDIR="$2"
                shift 2
                ;;
            -c|--confdir)
                CONFDIR="$2"
                shift 2
                ;;
            -d|--deps)
                install_deps=true
                shift
                ;;
            -t|--test)
                run_tests_after=true
                shift
                ;;
            -f|--force)
                force_install=true
                shift
                ;;
            -u|--uninstall)
                uninstall_mode=true
                shift
                ;;
            *)
                log_error "Option inconnue: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Afficher la configuration
    log_info "Configuration d'installation:"
    log_info "  Préfixe: $PREFIX"
    log_info "  Binaires: $BINDIR"
    log_info "  Pages man: $MANDIR"
    log_info "  Configuration: $CONFDIR"
    log_info "  Version: $VERSION"
    
    # Mode désinstallation
    if [ "$uninstall_mode" = true ]; then
        uninstall_git_mirror
        exit 0
    fi
    
    # Vérifier si déjà installé
    if check_installed && [ "$force_install" != true ]; then
        log_error "git-mirror est déjà installé. Utilisez --force pour forcer l'installation"
        exit 1
    fi
    
    # Installer les dépendances si demandé
    if [ "$install_deps" = true ]; then
        install_dependencies
    fi
    
    # Installer git-mirror
    install_git_mirror
    
    # Exécuter les tests si demandé
    if [ "$run_tests_after" = true ]; then
        run_tests
    fi
    
    # Afficher les instructions finales
    log_success "Installation terminée avec succès!"
    log_info "Pour utiliser git-mirror:"
    log_info "  1. Ajoutez $BINDIR à votre PATH"
    log_info "  2. Exécutez: git-mirror --help"
    log_info "  3. Configurez votre token GitHub: export GITHUB_TOKEN=your_token"
    
    if [ "$install_deps" != true ]; then
        log_warning "N'oubliez pas d'installer les dépendances: $0 --deps"
    fi
}

# Exécuter la fonction principale
main "$@"
