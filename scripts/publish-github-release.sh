#!/bin/bash
# Script pour publier une release GitHub
# Utilise l'API GitHub pour créer une release avec les artefacts

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

readonly VERSION="2.0.0"
readonly RELEASE_DIR="$PROJECT_ROOT/releases/v${VERSION}"
readonly GITHUB_API="https://api.github.com"

# Couleurs
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
}

# Vérifier les prérequis
check_prerequisites() {
    log_info "Vérification des prérequis..."
    
    local errors=0
    
    # Vérifier curl
    if ! command -v curl >/dev/null 2>&1; then
        log_error "curl n'est pas installé"
        errors=$((errors + 1))
    fi
    
    # Vérifier jq
    if ! command -v jq >/dev/null 2>&1; then
        log_error "jq n'est pas installé"
        errors=$((errors + 1))
    fi
    
    # Vérifier GITHUB_TOKEN
    if [ -z "${GITHUB_TOKEN:-}" ]; then
        log_warning "GITHUB_TOKEN non défini"
        log_info "Le token peut être défini via: export GITHUB_TOKEN=your_token"
        log_info "Ou via un fichier: .github_token (non tracké)"
    fi
    
    # Vérifier que le tag existe
    cd "$PROJECT_ROOT"
    if ! git rev-parse "v${VERSION}" >/dev/null 2>&1; then
        log_error "Le tag v${VERSION} n'existe pas"
        log_info "Créez-le d'abord avec: bash scripts/create-git-tag.sh"
        errors=$((errors + 1))
    fi
    
    # Vérifier les artefacts
    if [ ! -f "$RELEASE_DIR/git-mirror-${VERSION}.tar.gz" ]; then
        log_error "Archive manquante: $RELEASE_DIR/git-mirror-${VERSION}.tar.gz"
        errors=$((errors + 1))
    fi
    
    if [ $errors -gt 0 ]; then
        log_error "$errors erreur(s) trouvée(s)"
        return 1
    fi
    
    log_success "Prérequis vérifiés"
    return 0
}

# Détecter le repo GitHub
detect_repo() {
    log_info "Détection du dépôt GitHub..."
    
    cd "$PROJECT_ROOT"
    
    local remote_url
    remote_url=$(git config --get remote.origin.url 2>/dev/null || echo "")
    
    if [ -z "$remote_url" ]; then
        log_error "Aucun remote 'origin' trouvé"
        return 1
    fi
    
    # Extraire owner/repo depuis l'URL
    local repo_name
    if [[ "$remote_url" =~ github\.com[:/]([^/]+)/([^/]+)\.git? ]]; then
        repo_name="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
        # Enlever .git
        repo_name="${repo_name%.git}"
        echo "$repo_name"
        return 0
    else
        log_error "Impossible de détecter le repo GitHub depuis: $remote_url"
        log_info "Vous pouvez le spécifier manuellement via: GITHUB_REPO=owner/repo"
        return 1
    fi
}

# Créer la release via API GitHub
create_release() {
    local repo="$1"
    local token="$2"
    
    log_info "Création de la release GitHub..."
    
    # Lire le body depuis RELEASE_NOTES.md
    local release_body
    if [ -f "$RELEASE_DIR/RELEASE_NOTES.md" ]; then
        # Échapper pour JSON
        release_body=$(jq -Rs . < "$RELEASE_DIR/RELEASE_NOTES.md")
    else
        release_body="\"Release v${VERSION}\""
    fi
    
    # Créer la release
    local response
    response=$(curl -s -w "\n%{http_code}" \
        -X POST \
        -H "Authorization: token $token" \
        -H "Accept: application/vnd.github.v3+json" \
        "$GITHUB_API/repos/$repo/releases" \
        -d "{
            \"tag_name\": \"v${VERSION}\",
            \"name\": \"Git Mirror v${VERSION}\",
            \"body\": ${release_body},
            \"draft\": false,
            \"prerelease\": false
        }")
    
    local http_code
    http_code=$(echo "$response" | tail -n1)
    local body
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" -eq 201 ]; then
        local upload_url
        upload_url=$(echo "$body" | jq -r '.upload_url' | sed 's/{.*}//')
        log_success "✅ Release créée"
        echo "$upload_url"
        return 0
    else
        log_error "Échec de la création (HTTP $http_code)"
        echo "$body" | jq -r '.message' 2>/dev/null || echo "$body"
        return 1
    fi
}

# Uploader les artefacts
upload_assets() {
    local upload_url="$1"
    local repo="$2"
    local token="$3"
    
    log_info "Upload des artefacts..."
    
    local archive_file="$RELEASE_DIR/git-mirror-${VERSION}.tar.gz"
    local filename
    filename=$(basename "$archive_file")
    
    # Upload l'archive
    local response
    response=$(curl -s -w "\n%{http_code}" \
        -X POST \
        -H "Authorization: token $token" \
        -H "Accept: application/vnd.github.v3+json" \
        -H "Content-Type: application/gzip" \
        "$upload_url?name=$filename" \
        --data-binary @"$archive_file")
    
    local http_code
    http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" -eq 201 ]; then
        log_success "✅ Archive uploadée: $filename"
        return 0
    else
        log_error "Échec de l'upload (HTTP $http_code)"
        return 1
    fi
}

# Générer les instructions manuelles
generate_manual_instructions() {
    local repo="$1"
    
    cat > "$RELEASE_DIR/GITHUB_RELEASE_INSTRUCTIONS.md" <<EOF
# Instructions pour Publier la Release GitHub Manuellement

**Repository**: $repo
**Version**: v${VERSION}
**Tag**: v${VERSION} (doit exister dans Git)

## Méthode 1: Via Interface Web GitHub

1. Aller sur: https://github.com/$repo/releases/new

2. Sélectionner le tag: **v${VERSION}**

3. Titre: **Git Mirror v${VERSION}**

4. Description: Copier le contenu de \`RELEASE_NOTES.md\`

5. Uploader les fichiers:
   - \`git-mirror-${VERSION}.tar.gz\`

6. Cocher: ☑️ Set as the latest release

7. Cliquer: **Publish release**

## Méthode 2: Via GitHub CLI (gh)

\`\`\`bash
cd $PROJECT_ROOT

# S'authentifier
gh auth login

# Créer la release
gh release create v${VERSION} \\
  --title "Git Mirror v${VERSION}" \\
  --notes-file releases/v${VERSION}/RELEASE_NOTES.md \\
  releases/v${VERSION}/git-mirror-${VERSION}.tar.gz
\`\`\`

## Méthode 3: Via API (avec token)

\`\`\`bash
export GITHUB_TOKEN=your_token_here
bash scripts/publish-github-release.sh
\`\`\`

## Vérification

Après publication, vérifier:
- https://github.com/$repo/releases/tag/v${VERSION}
- L'archive est téléchargeable
- Les release notes sont correctes

EOF
    
    log_info "Instructions créées: $RELEASE_DIR/GITHUB_RELEASE_INSTRUCTIONS.md"
}

# Fonction principale
main() {
    log_info "=== Publication Release GitHub v${VERSION} ==="
    echo ""
    
    # Vérifier les prérequis
    if ! check_prerequisites; then
        log_error "Prérequis non satisfaits"
        return 1
    fi
    
    echo ""
    
    # Détecter le repo
    local repo
    repo="${GITHUB_REPO:-$(detect_repo)}"
    
    if [ -z "$repo" ]; then
        log_error "Impossible de détecter le repo"
        log_info "Spécifiez-le via: GITHUB_REPO=owner/repo"
        return 1
    fi
    
    log_success "Dépôt détecté: $repo"
    
    echo ""
    
    # Vérifier le token
    local token
    token="${GITHUB_TOKEN:-}"
    
    if [ -f "$PROJECT_ROOT/.github_token" ]; then
        token=$(cat "$PROJECT_ROOT/.github_token" | tr -d '\n\r ')
    fi
    
    if [ -z "$token" ]; then
        log_warning "GITHUB_TOKEN non disponible"
        log_info "Génération d'instructions manuelles..."
        generate_manual_instructions "$repo"
        echo ""
        log_info "Consultez: $RELEASE_DIR/GITHUB_RELEASE_INSTRUCTIONS.md"
        return 0
    fi
    
    # Créer la release
    local upload_url
    upload_url=$(create_release "$repo" "$token")
    
    if [ -z "$upload_url" ]; then
        log_error "Échec de la création de la release"
        generate_manual_instructions "$repo"
        return 1
    fi
    
    echo ""
    
    # Uploader les artefacts
    if upload_assets "$upload_url" "$repo" "$token"; then
        echo ""
        log_success "=== Release GitHub Publiée ==="
        log_info "URL: https://github.com/$repo/releases/tag/v${VERSION}"
    else
        log_error "Erreur lors de l'upload des artefacts"
        return 1
    fi
}

main "$@"
