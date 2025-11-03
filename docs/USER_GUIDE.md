# Guide Utilisateur - Git Mirror

## Table des Matières

1. [Introduction](#introduction)
2. [Installation](#installation)
3. [Utilisation de Base](#utilisation-de-base)
4. [Options Avancées](#options-avancées)
5. [Exemples d'Utilisation](#exemples-dutilisation)
6. [Configuration](#configuration)
7. [Dépannage](#dépannage)

## Introduction

Git Mirror est un outil puissant pour cloner et synchroniser des dépôts GitHub en masse. Il supporte le clonage d'utilisateurs entiers, d'organisations, avec filtrage, mode parallèle, cache, et bien plus.

### Fonctionnalités Principales

- ✅ Clonage en masse d'utilisateurs/organisations GitHub
- ✅ Mode parallèle pour accélérer les opérations
- ✅ Cache intelligent pour éviter les appels API répétés
- ✅ Filtrage avancé (par nom, fork, type)
- ✅ Mode incrémental (ne traite que les dépôts modifiés)
- ✅ Authentification flexible (Token, SSH, Public)
- ✅ Métriques et rapports détaillés
- ✅ Mode interactif pour sélectionner les dépôts
- ✅ Hooks personnalisables

## Installation

### Prérequis

- Bash 4.0+
- Git
- jq (pour le parsing JSON)
- curl (pour les appels API)
- GNU parallel (optionnel, pour le mode parallèle)

### Installation depuis le code source

```bash
# Cloner le dépôt
git clone <repository-url>
cd git-mirror

# Installer les dépendances
bash scripts/install-dependencies.sh

# Rendre le script exécutable
chmod +x git-mirror.sh
```

## Utilisation de Base

### Syntaxe Générale

```bash
./git-mirror.sh [OPTIONS] <context> <username_or_org>
```

### Exemples Simples

```bash
# Cloner tous les dépôts d'un utilisateur
./git-mirror.sh users octocat

# Cloner tous les dépôts d'une organisation
./git-mirror.sh orgs github

# Cloner dans un répertoire spécifique
./git-mirror.sh users octocat --dest ./my-repos

# Cloner uniquement la branche principale
./git-mirror.sh users octocat --branch main
```

## Options Avancées

### Authentification

```bash
# Utiliser un token GitHub (recommandé)
export GITHUB_TOKEN="ghp_votre_token"
./git-mirror.sh users octocat

# Utiliser une clé SSH
export GITHUB_SSH_KEY="/path/to/key"
./git-mirror.sh users octocat

# Forcer l'authentification publique
./git-mirror.sh users octocat --auth public
```

### Mode Parallèle

```bash
# Activer le mode parallèle avec 4 jobs
./git-mirror.sh users octocat --parallel --jobs 4

# Mode parallèle automatique (détecte les ressources système)
./git-mirror.sh users octocat --parallel --auto-tune
```

### Filtrage

```bash
# Exclure les forks
./git-mirror.sh users octocat --exclude-forks

# Filtrer par nom (pattern)
./git-mirror.sh users octocat --filter "*-test"

# Inclure uniquement certains dépôts
./git-mirror.sh users octocat --include "project-*"

# Exclure certains dépôts
./git-mirror.sh users octocat --exclude "deprecated-*"
```

### Mode Incrémental

```bash
# Mode incrémental (ne traite que les dépôts modifiés)
./git-mirror.sh users octocat --incremental

# La première exécution clone tout, les suivantes ne mettent à jour que les modifiés
```

### Options de Clonage

```bash
# Clone shallow (seulement le dernier commit)
./git-mirror.sh users octocat --depth 1

# Clone sans checkout (références seulement)
./git-mirror.sh users octocat --no-checkout

# Clone une seule branche
./git-mirror.sh users octocat --single-branch

# Appliquer un filtre Git
./git-mirror.sh users octocat --filter "blob:none"
```

### Cache et Performance

```bash
# Désactiver le cache
./git-mirror.sh users octocat --no-cache

# Configurer le TTL du cache (en secondes)
export GIT_MIRROR_CACHE_TTL=7200
./git-mirror.sh users octocat

# Timeout personnalisé (en secondes)
./git-mirror.sh users octocat --timeout 60
```

### Mode Interactif

```bash
# Mode interactif (sélectionner les dépôts à traiter)
./git-mirror.sh users octocat --interactive

# Mode avec confirmation
./git-mirror.sh users octocat --confirm
```

### Métriques et Rapports

```bash
# Activer les métriques
./git-mirror.sh users octocat --metrics

# Exporter les métriques en JSON
./git-mirror.sh users octocat --metrics --metrics-format json --metrics-file report.json

# Exporter en CSV
./git-mirror.sh users octocat --metrics --metrics-format csv --metrics-file report.csv

# Exporter en HTML
./git-mirror.sh users octocat --metrics --metrics-format html --metrics-file report.html
```

### Mode Dry-Run

```bash
# Simuler l'exécution sans modifier quoi que ce soit
./git-mirror.sh users octocat --dry-run
```

### Mode Verbose

```bash
# Niveau de verbosité (0-3)
./git-mirror.sh users octocat --verbose 2

# Mode silencieux
./git-mirror.sh users octocat --quiet
```

## Exemples d'Utilisation

### Scénario 1: Sauvegarde Complète d'un Utilisateur

```bash
# Cloner tous les dépôts d'un utilisateur avec authentification
export GITHUB_TOKEN="ghp_votre_token"
./git-mirror.sh users octocat \
  --dest ./backups/octocat \
  --parallel --jobs 8 \
  --metrics --metrics-format html \
  --incremental
```

### Scénario 2: Synchronisation d'une Organisation

```bash
# Synchroniser une organisation en mode incrémental
./git-mirror.sh orgs github \
  --dest ./github-repos \
  --incremental \
  --exclude-forks \
  --filter "*-docs"
```

### Scénario 3: Clonage Sélectif Interactif

```bash
# Mode interactif pour sélectionner les dépôts
./git-mirror.sh users octocat \
  --interactive \
  --dest ./selected-repos
```

### Scénario 4: Backup Rapide avec Filtrage

```bash
# Cloner rapidement avec filtrage et mode parallèle
./git-mirror.sh users octocat \
  --parallel --jobs 10 \
  --depth 1 \
  --filter "blob:none" \
  --exclude-forks \
  --include "important-*"
```

## Configuration

### Variables d'Environnement

```bash
# Token GitHub
export GITHUB_TOKEN="ghp_votre_token"

# Clé SSH
export GITHUB_SSH_KEY="/path/to/key"

# Méthode d'authentification forcée
export GITHUB_AUTH_METHOD="token"  # ou "ssh" ou "public"

# Répertoire de destination par défaut
export GIT_MIRROR_DEST_DIR="./repositories"

# TTL du cache (secondes)
export GIT_MIRROR_CACHE_TTL=3600

# Nombre de jobs parallèles par défaut
export GIT_MIRROR_PARALLEL_JOBS=4
```

### Fichiers de Configuration

Le script peut utiliser des fichiers de configuration JSON :

```bash
# Sauvegarder la configuration actuelle
./git-mirror.sh users octocat --save-config config.json

# Charger une configuration
./git-mirror.sh --load-config config.json users octocat
```

## Dépannage

### Problèmes Courants

#### Erreur: Rate Limit Exceeded

```bash
# Solution: Utiliser un token GitHub
export GITHUB_TOKEN="ghp_votre_token"
./git-mirror.sh users octocat
```

#### Erreur: Permission Denied

```bash
# Vérifier les permissions du répertoire de destination
chmod +w ./repositories

# Ou utiliser un autre répertoire
./git-mirror.sh users octocat --dest /tmp/repos
```

#### Erreur: jq not found

```bash
# Installer jq
# Sur Ubuntu/Debian:
sudo apt-get install jq

# Sur macOS:
brew install jq

# Sur Fedora:
sudo dnf install jq
```

#### Mode Parallèle Non Disponible

```bash
# Installer GNU parallel
# Sur Ubuntu/Debian:
sudo apt-get install parallel

# Sur macOS:
brew install parallel
```

### Logs et Debug

```bash
# Activer le mode verbose pour plus d'informations
./git-mirror.sh users octocat --verbose 3

# Vérifier les logs dans le répertoire de cache
ls -la .git-mirror-cache/

# Vérifier l'état d'exécution
cat .git-mirror-state.json
```

### Support

Pour plus d'aide :
- Consultez la documentation complète dans `docs/`
- Vérifiez les issues sur GitHub
- Consultez les logs avec `--verbose 3`

## Fonctionnalités Avancées

### Hooks Personnalisés

Créez des hooks dans le répertoire `hooks/` :

```bash
# hooks/post-clone.sh - Exécuté après chaque clonage
#!/bin/bash
echo "Repository $1 cloned to $2"

# hooks/post-update.sh - Exécuté après chaque mise à jour
#!/bin/bash
echo "Repository $1 updated at $2"

# hooks/on-error.sh - Exécuté en cas d'erreur
#!/bin/bash
echo "Error with repository $1: $4"
```

Activez les hooks :
```bash
export HOOKS_ENABLED=true
./git-mirror.sh users octocat
```

### Mode Resume

Si l'exécution est interrompue, vous pouvez reprendre :

```bash
./git-mirror.sh users octocat --resume
```

### Filtrage Avancé avec Fichiers

```bash
# Créer un fichier avec les patterns à inclure
echo "project-*" > include.txt
echo "important-*" >> include.txt

# Créer un fichier avec les patterns à exclure
echo "test-*" > exclude.txt
echo "deprecated-*" >> exclude.txt

# Utiliser les fichiers
./git-mirror.sh users octocat \
  --include-file include.txt \
  --exclude-file exclude.txt
```

## Meilleures Pratiques

1. **Utilisez un token GitHub** pour éviter les limites de taux
2. **Activez le mode incrémental** pour les synchronisations régulières
3. **Utilisez le mode parallèle** pour accélérer les gros clonages
4. **Configurez le cache** pour réduire les appels API
5. **Utilisez les filtres** pour ne cloner que ce dont vous avez besoin
6. **Activez les métriques** pour suivre les performances
7. **Testez avec --dry-run** avant les grandes opérations

## Licence

Voir le fichier LICENSE pour plus d'informations.
