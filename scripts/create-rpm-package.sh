#!/bin/bash
# Script pour créer un package RPM
# Usage: ./scripts/create-rpm-package.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
VERSION="${1:-3.1.0}"
RPMBUILD_DIR="$HOME/rpmbuild"

echo "Création du package RPM pour git-mirror ${VERSION}..."

# Créer les répertoires rpmbuild si nécessaire
mkdir -p "$RPMBUILD_DIR"/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}

# Créer le tarball source
SPECFILE="$RPMBUILD_DIR/SPECS/git-mirror.spec"
cat > "$SPECFILE" << EOF
Summary: Clone or update all GitHub repositories
Name: git-mirror
Version: ${VERSION}
Release: 1%{?dist}
License: MIT
Group: Applications/System
Source0: %{name}-%{version}.tar.gz
BuildArch: noarch
URL: https://github.com/ZarTek-Creole/git-mirror

Requires: bash >= 4.4, git >= 2.25, curl >= 7.68, jq >= 1.6, parallel

%description
Git Mirror is an advanced script that allows you to clone or update all GitHub
repositories belonging to a user or organization. It uses the GitHub API and
supports authentication, parallel processing, filtering, and offers a wide
range of configuration options.

Features:
- Multiple authentication methods (Token, SSH, Public)
- Parallel processing with GNU parallel
- Advanced filtering (include/exclude patterns, forks, repo types)
- Metrics export (JSON, CSV, HTML)
- Incremental mode for modified repos only
- Resumable execution after interruption
- API caching to reduce redundant calls
- Performance profiling capabilities

%prep
%setup -q

%build
# Nothing to build for shell script

%install
install -d %{buildroot}/usr/bin
install -d %{buildroot}/usr/share/git-mirror/lib
install -d %{buildroot}/usr/share/git-mirror/config
install -d %{buildroot}/usr/share/doc/git-mirror
install -d %{buildroot}/usr/share/man/man1

install -m 755 git-mirror.sh %{buildroot}/usr/bin/git-mirror
cp -r lib/* %{buildroot}/usr/share/git-mirror/lib/
cp -r config/* %{buildroot}/usr/share/git-mirror/config/
cp README.md LICENSE %{buildroot}/usr/share/doc/git-mirror/
cp docs/git-mirror.1.gz %{buildroot}/usr/share/man/man1/

%clean
rm -rf %{buildroot}

%files
/usr/bin/git-mirror
/usr/share/git-mirror/
/usr/share/doc/git-mirror/
/usr/share/man/man1/git-mirror.1.gz

%changelog
* $(date "+%a %b %d %Y") ZarTek-Creole <11725850+ZarTek-Creole@users.noreply.github.com> -
 ${VERSION}-1
- Initial RPM package for git-mirror ${VERSION}
EOF

# Créer le tarball
cd "$PROJECT_DIR"
tar -czf "$RPMBUILD_DIR/SOURCES/git-mirror-${VERSION}.tar.gz" \
    --exclude='.git' \
    --exclude='.gitignore' \
    --exclude='*~' \
    --exclude='*.swp' \
    git-mirror.sh lib config docs README.md LICENSE CONTRIBUTING.md CHANGELOG.md

# Construire le RPM
cd "$RPMBUILD_DIR"
rpmbuild -ba SPECS/git-mirror.spec

echo "Package RPM créé : $RPMBUILD_DIR/RPMS/noarch/git-mirror-${VERSION}-1.noarch.rpm"
echo "Pour l'installer : sudo rpm -ivh $RPMBUILD_DIR/RPMS/noarch/git-mirror-${VERSION}-1.noarch.rpm"

