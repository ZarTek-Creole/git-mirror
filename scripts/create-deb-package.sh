#!/bin/bash
# Script pour créer un package Debian .deb
# Usage: ./scripts/create-deb-package.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
VERSION="${1:-3.1.0}"
DEB_NAME="git-mirror-${VERSION}"

echo "Création du package Debian pour git-mirror ${VERSION}..."

# Créer le répertoire de travail
BUILD_DIR="/tmp/${DEB_NAME}"
mkdir -p "$BUILD_DIR/DEBIAN"
mkdir -p "$BUILD_DIR/usr/bin"
mkdir -p "$BUILD_DIR/usr/share/git-mirror/lib"
mkdir -p "$BUILD_DIR/usr/share/git-mirror/config"
mkdir -p "$BUILD_DIR/usr/share/git-mirror/docs"
mkdir -p "$BUILD_DIR/usr/share/doc/git-mirror"
mkdir -p "$BUILD_DIR/usr/share/man/man1"

# Copier les fichiers
cp "$PROJECT_DIR/git-mirror.sh" "$BUILD_DIR/usr/bin/git-mirror"
chmod +x "$BUILD_DIR/usr/bin/git-mirror"

# Copier les modules
cp -r "$PROJECT_DIR/lib/"* "$BUILD_DIR/usr/share/git-mirror/lib/"
cp -r "$PROJECT_DIR/config/"* "$BUILD_DIR/usr/share/git-mirror/config/"

# Copier la documentation
cp "$PROJECT_DIR/README.md" "$BUILD_DIR/usr/share/doc/git-mirror/"
cp "$PROJECT_DIR/LICENSE" "$BUILD_DIR/usr/share/doc/git-mirror/"

# Copier la man page
cp "$PROJECT_DIR/docs/git-mirror.1.gz" "$BUILD_DIR/usr/share/man/man1/"

# Créer le fichier control
cat > "$BUILD_DIR/DEBIAN/control" << EOF
Package: git-mirror
Version: ${VERSION}
Section: utils
Priority: optional
Architecture: all
Depends: bash (>= 4.4), git (>= 2.25), curl (>= 7.68), jq (>= 1.6), parallel
Maintainer: ZarTek-Creole <11725850+ZarTek-Creole@users.noreply.github.com>
Description: Clone or update all GitHub repositories for a user or organization
 Git Mirror is an advanced script that allows you to clone or update all GitHub
 repositories belonging to a user or organization. It uses the GitHub API and
 supports authentication, parallel processing, filtering, and offers a wide
 range of configuration options.
 .
 Features:
 - Multiple authentication methods (Token, SSH, Public)
 - Parallel processing with GNU parallel
 - Advanced filtering (include/exclude patterns, forks, repo types)
 - Metrics export (JSON, CSV, HTML)
 - Incremental mode for modified repos only
 - Resumable execution after interruption
 - API caching to reduce redundant calls
 - Performance profiling capabilities
Homepage: https://github.com/ZarTek-Creole/git-mirror
EOF

# Cré opted le fichier postinst
cat > "$BUILD_DIR/DEBIAN/postinst" << 'EOF'
#!/bin/bash
# postinst script for git-mirror

set -e

# Update man database
if command -v mandb >/dev/null 2>&1; then
    mandb -q
fi

# Create configuration directory if it doesn't exist
mkdir -p /etc/git-mirror 2>/dev/null || true

exit 0
EOF

chmod +x "$BUILD_DIR/DEBIAN/postinst"

# Créer le package
dpkg-deb --build "$BUILD_DIR" "$PROJECT_DIR/git-mirror_${VERSION}_all.deb"

echo "Package créé : $PROJECT_DIR/git-mirror_${VERSION}_all.deb"
echo "Pour l'installer : sudo dpkg -i git-mirror_${VERSION}_all.deb"

