# Git Mirror

[![CI Status](https://github.com/ZarTek-Creole/git-mirror/workflows/CI/badge.svg)](https://github.com/ZarTek-Creole/git-mirror/actions)
[![ShellCheck](https://img.shields.io/badge/shellcheck-passed-brightgreen)](https://www.shellcheck.net/)
[![License](https://img.shields.io/badge/license-MIT-blue)](LICENSE)
[![Bash](https://img.shields.io/badge/bash-4.4%2B-green)](https://www.gnu.org/software/bash/)
[![Version](https://img.shields.io/badge/version-2.5.0-orange)](CHANGELOG.md)

## Table des Matières

- [Résumé](#résumé)
- [Description](#description)
- [Caractéristiques principales](#caractéristiques-principales)
- [Dépendances & Prérequis](#dépendances--prérequis)
- [Utilisation](#utilisation)
- [Architecture du Projet](#architecture-du-projet)
- [Documentation](#documentation)
- [Matrice de Compatibilité](#matrice-de-compatibilité)
- [Notes importantes](#notes-importantes)
- [Limitations](#limitations)
- [Problèmes courants et solutions](#problèmes-courants-et-solutions)
- [Contributions](#contributions)
- [Licence](#licence)
- [Auteur](#auteur)
- [Donations](#donations)

## Résumé

Git Mirror est un script avancé permettant de cloner ou mettre à jour tous les dépôts GitHub d'un utilisateur ou d'une organisation. Il supporte l'authentification, le traitement parallèle, les filtres, et offre une large gamme d'options de configuration.

## Description

Ce script Bash permet de cloner ou mettre à jour tous les dépôts GitHub (avec ou sans forks selon vos préférences) appartenant à un utilisateur ou une organisation donnée. Il utilise l'API GitHub et l'outil jq pour récupérer la liste des dépôts et exécute la commande git clone ou git pull sur chaque dépôt. Le script définit également un délai d'expiration configurable pour la commande git afin d'éviter les exécutions de commandes interminables.

## Caractéristiques principales

- 🔐 **Authentification multiple** : Token GitHub, clé SSH, ou accès public
- ⚡ **Traitement parallèle** : Utilisation de GNU parallel pour accélérer les opérations
- 🔍 **Filtrage avancé** : Inclure/exclure des dépôts par patterns
- 📊 **Métriques** : Export des statistiques en JSON, CSV ou HTML
- 🎯 **Mode incrémental** : Traite uniquement les dépôts modifiés depuis la dernière synchronisation
- 🔄 **Mode résumable** : Reprendre une exécution interrompue
- 🚫 **Exclusion des forks** : Option pour exclure les dépôts forké
- 🔐 **Filtrage par type** : Récupérer public, privé, ou tous les dépôts
- 💾 **Cache API** : Réduction des appels API redondants
- ⏱️ **Profiling** : Analyser les performances du script

## Dépendances & Prérequis

Pour utiliser ce script, vous devez avoir les outils suivants installés sur votre ordinateur :

- **git** (version 2.25+) : Gestionnaire de versions
  - Ubuntu/Debian : `sudo apt-get install git`
  - CentOS/Fedora : `sudo yum install git`
  - MacOS : `brew install git`
  - [Télécharger Git](https://git-scm.com/downloads)

- **jq** (version 1.6+) : Manipulation de JSON en ligne de commande
  - Ubuntu/Debian : `sudo apt-get install jq`
  - CentOS/Fedora : `sudo yum install jq`
  - MacOS : `brew install jq`
  - [Télécharger jq](https://stedolan.github.io/jq/)

- **curl** (version 7.68+) : Transfert de données
  - Ubuntu/Debian : `sudo apt-get install curl`
  - CentOS/Fedora : `sudo yum install curl`
  - MacOS : `brew install curl`
  - [Télécharger curl](https://curl.haxx.se/download.html)

- **GNU parallel** (optionnel) : Pour le traitement parallèle
  - Ubuntu/Debian : `sudo apt-get install parallel`
  - CentOS/Fedora : `sudo yum install parallel`
  - MacOS : `brew install parallel`

## Installation Rapide

```bash
# Cloner le dépôt
git clone https://github.com/ZarTek-Creole/git-mirror.git
cd git-mirror

# Rendre le script exécutable
chmod +x git-mirror.sh

# Vérifier les dépendances
./git-mirror.sh --help
```

## Utilisation

### Syntaxe

```bash
./git-mirror.sh [OPTIONS] context username_or_orgname
```

### Arguments

- `context` : Type de contexte (`users` ou `orgs`)
- `username_or_orgname` : Nom d'utilisateur ou d'organisation GitHub

### Options principales

#### Général

- `-d, --destination DIR` : Répertoire de destination (défaut: ./repositories)
- `-b, --branch BRANCH` : Branche spécifique à cloner (défaut: branche par défaut)
- `-h, --help` : Afficher l'aide

#### Options Git

- `-f, --filter FILTER` : Filtre Git pour le clonage partiel (ex: blob:none)
- `-n, --no-checkout` : Cloner sans checkout initial
- `-s, --single-branch` : Cloner une seule branche
- `--depth DEPTH` : Profondeur du clonage shallow (défaut: 1)

#### Performance

- `--parallel JOBS` : Nombre de jobs parallèles (défaut: 1, nécessite GNU parallel)
- `--timeout SECONDS` : Timeout pour les opérations Git (défaut: 30)
- `--profile` : Activer le profiling de performance

#### Filtrage

- `--exclude PATTERN` : Exclure les repos correspondant au pattern (peut être utilisé plusieurs fois)
- `--exclude-file FILE` : Lire les patterns d'exclusion depuis un fichier
- `--include PATTERN` : Inclure uniquement les repos correspondant au pattern (peut être utilisé plusieurs fois)
- `--include-file FILE` : Lire les patterns d'inclusion depuis un fichier
- `--exclude-forks` : Exclure les dépôts forké de la récupération
- `--repo-type TYPE` : Type de dépôts à récupérer : `all`, `public`, `private` (défaut: all)

#### Mode

- `--resume` : Reprendre une exécution interrompue
- `--incremental` : Mode incrémental (traite seulement les repos modifiés)
- `--interactive` : Mode interactif avec confirmations
- `--confirm` : Afficher un résumé et demander confirmation avant de commencer
- `--yes, -y` : Mode automatique (ignorer toutes les confirmations)
- `--dry-run` : Simulation sans actions réelles

#### Sortie

- `-v, --verbose` : Mode verbeux (peut être utilisé plusieurs fois: -vv, -vvv)
- `-q, --quiet` : Mode silencieux (sortie minimale)
- `--metrics FILE` : Exporter les métriques vers un fichier (formats: json,csv,html)

#### Avancé

- `--skip-count` : Éviter le calcul du nombre total de dépôts (utile si limite API)
- `--no-cache` : Désactiver l'utilisation du cache API (forcer les appels API)

### Exemples

#### Utilisation de base

```bash
# Cloner tous les dépôts d'un utilisateur
./git-mirror.sh users ZarTek-Creole

# Cloner dans un répertoire spécifique
./git-mirror.sh -d /path/to/repos users ZarTek-Creole

# Cloner une organisation
./git-mirror.sh orgs microsoft
```

#### Options Git avancées

```bash
# Cloner avec filtre blob:none (économie d'espace)
./git-mirror.sh -f blob:none users ZarTek-Creole

# Cloner une seule branche (main)
./git-mirror.sh -b main -s users ZarTek-Creole

# Cloner sans checkout initial
./git-mirror.sh -n users ZarTek-Creole

# Cloner avec profondeur shallow
./git-mirror.sh --depth 5 users ZarTek-Creole
```

#### Traitement parallèle

```bash
# Cloner avec 5 jobs parallèles
./git-mirror.sh --parallel 5 users ZarTek-Creole

# Cloner avec 10 jobs parallèles et timeout augmenté
./git-mirror.sh --parallel 10 --timeout 60 users ZarTek-Creole
```

#### Filtrage

```bash
# Exclure certains dépôts
./git-mirror.sh --exclude "test-*" --exclude "demo-*" users ZarTek-Creole

# Exclure depuis un fichier
./git-mirror.sh --exclude-file exclude-patterns.txt users ZarTek-Creole

# Inclure uniquement certains dépôts
./git-mirror.sh --include "project-*" users ZarTek-Creole

# Exclure les forks
./git-mirror.sh --exclude-forks users ZarTek-Creole

# Récupérer uniquement les dépôts privés (authentification requise)
./git-mirror.sh --repo-type private users ZarTek-Creole

# Récupérer uniquement les dépôts publics
./git-mirror.sh --repo-type public users ZarTek-Creole

# Combiner les filtres
./git-mirror.sh --exclude-forks --repo-type public users ZarTek-Creole
```

#### Modes d'exécution

```bash
# Mode dry-run (simulation)
./git-mirror.sh --dry-run -vv users microsoft

# Mode silencieux
./git-mirror.sh -q users ZarTek-Creole

# Mode verbeux (plus de détails)
./git-mirror.sh -vvv users ZarTek-Creole

# Mode incrémental (seulement les dépôts modifiés)
./git-mirror.sh --incremental users microsoft

# Reprendre une exécution interrompue
./git-mirror.sh --resume users microsoft

# Mode interactif
./git-mirror.sh --interactive users ZarTek-Creole

# Mode automatique (sans confirmation)
./git-mirror.sh --yes users ZarTek-Creole
```

#### Métriques et monitoring

```bash
# Exporter les métriques en JSON
./git-mirror.sh --metrics metrics.json users ZarTek-Creole

# Exporter en CSV
./git-mirror.sh --metrics metrics.csv --profile users ZarTek-Creole

# Exporter en HTML
./git-mirror.sh --metrics report.html users ZarTek-Creole

# Profiling des performances
./git-mirror.sh --profile users ZarTek-Creole
```

#### Authentification

```bash
# Utiliser un token GitHub (variable d'environnement)
export GITHUB_TOKEN="ghp_xxxxxxxxxxxx"
./git-mirror.sh --repo-type all users ZarTek-Creole

# Utiliser une clé SSH
export GITHUB_SSH_KEY="/path/to/id_rsa"
export GITHUB_AUTH_METHOD="ssh"
./git-mirror.sh users ZarTek-Creole

# Forcer l'authentification publique
export GITHUB_AUTH_METHOD="public"
./git-mirror.sh users ZarTek-Creole
```

### Variables d'environnement

- `GITHUB_TOKEN` : Token d'accès personnel GitHub
- `GITHUB_SSH_KEY` : Chemin vers la clé SSH privée
- `GITHUB_AUTH_METHOD` : Force la méthode d'authentification (`token`, `ssh`, `public`)

## Architecture du Projet

Ce projet utilise une architecture modulaire avec 13 modules spécialisés organisés dans `lib/`. Le script principal `git-mirror.sh` agit comme une façade orchestrant l'ensemble.

📚 **Pour plus de détails techniques** : Consultez [ARCHITECTURE.md](docs/ARCHITECTURE.md)

```
git-mirror/
├── git-mirror.sh          # Script principal (928 lignes)
├── config/                 # Configuration
│   ├── config.sh          # Config principale (330 lignes)
│   └── *.conf             # 12 fichiers de config spécialisés
├── lib/                    # 13 modules fonctionnels (3905 lignes)
│   ├── api/               # API GitHub
│   ├── auth/              # Authentification
│   ├── cache/             # Cache API
│   ├── filters/           # Filtrage
│   ├── git/               # Opérations Git
│   ├── incremental/       # Mode incrémental
│   ├── interactive/       # Mode interactif
│   ├── logging/           # Système de logs
│   ├── metrics/           # Métriques
│   ├── parallel/          # Parallélisation
│   ├── state/             # Gestion d'état
│   ├── utils/             # Utilitaires (profiling)
│   └── validation/        # Validation
└── tests/                  # 7 catégories de tests
    ├── unit/              # Tests unitaires (13 fichiers)
    ├── integration/       # Tests d'intégration
    ├── regression/        # Tests de régression
    ├── load/              # Tests de charge
    ├── mocks/             # Données mockées
    └── utils/             # Utilitaires de test
```

## Documentation

### Option --repo-type

Permet de filtrer les dépôts par type :

- `all` (défaut) : Récupère tous les dépôts (public + privé, nécessite authentification)
- `public` : Récupère uniquement les dépôts publics
- `private` : Récupère uniquement les dépôts privés (nécessite authentification)

**Note** : L'authentification est requise pour accéder aux dépôts privés. Si vous n'êtes pas authentifié et que vous utilisez `--repo-type private` ou `--repo-type all` en mode public, le script basculera automatiquement en mode public.

### Option --exclude-forks

Exclut automatiquement les dépôts forké de la récupération. Utile pour :

- Éviter les duplicatas
- Réduire le temps de clonage
- Se concentrer sur les dépôts originaux

**Exemple** :

```bash
# Sans l'option (par défaut, inclus les forks)
./git-mirror.sh users ZarTek-Creole
# Résultat : 244 dépôts

# Avec l'option
./git-mirror.sh --exclude-forks users ZarTek-Creole
# Résultat : 208 dépôts (40 forks exclus)
```

### Mode parallèle

Le mode parallèle utilise GNU parallel pour accélérer le clonage. Recommandations :

- **5-10 jobs** : Pour une utilisation normale
- **10-20 jobs** : Si vous avez une connexion rapide
- **1 job** : En cas de problèmes de réseau

**Exemple** :

```bash
./git-mirror.sh --parallel 5 users ZarTek-Creole
```

### Mode incrémental

Le mode incrémental ne traite que les dépôts modifiés depuis la dernière synchronisation. Il utilise le cache pour stocker le timestamp de la dernière synchronisation.

```bash
# Première exécution (clone tous les dépôts)
./git-mirror.sh users ZarTek-Creole

# Exécution suivante (mise à jour seulement les modifiés)
./git-mirror.sh --incremental users ZarTek-Creole
```

### Filtres Avancés Combinés

Il est possible de combiner plusieurs filtres pour des synchronisations très précises :

```bash
# Exclure les forks ET les patterns spécifiques
./git-mirror.sh --exclude-forks --exclude "old-*" --exclude "deprecated-*" users ZarTek-Creole

# Inclure uniquement les projets spécifiques ET exclure les forks
./git-mirror.sh --include "project-*" --exclude-forks users ZarTek-Creole

# Combiner type de dépôt, forks et patterns
./git-mirror.sh --repo-type public --exclude-forks --exclude "test-*" orgs my-org

# Filtres depuis des fichiers
./git-mirror.sh --include-file important-repos.txt --exclude-file skip-repos.txt users ZarTek-Creole
```

### Configuration Avancée via Fichiers `.conf`

Le projet inclut 12 fichiers de configuration spécialisés dans `config/` :

- `git-mirror.conf` : Configuration par défaut du script
- `performance.conf` : Paramètres de performance et parallélisation
- `security.conf` : Configuration de sécurité
- `cicd.conf` : Configuration CI/CD
- `ci.conf` : Configuration d'intégration continue
- `deployment.conf` : Configuration de déploiement
- `testing.conf` : Configuration des tests
- `maintenance.conf` : Configuration de maintenance
- `dependencies.conf` : Gestion des dépendances
- `documentation.conf` : Configuration de documentation

Ces fichiers permettent de personnaliser le comportement du script sans modifier le code source.

## Matrice de Compatibilité

| OS | Bash | Git | jq | curl | GNU Parallel | Status |
|----|------|-----|----|----|-----------|--------|
| Ubuntu 20.04+ | 5.0+ | 2.25+ | 1.6+ | 7.68+ | Last | ✅ Complet |
| Debian 11+ | 5.0+ | 2.25+ | 1.6+ | 7.68+ | Last | ✅ Complet |
| CentOS 8+ | 4.4+ | 2.25+ | 1.6+ | 7.68+ | Last | ✅ Complet |
| Fedora 34+ | 5.0+ | 2.25+ | 1.6+ | 7.68+ | Last | ✅ Complet |
| macOS 11+ | 3.2+ | 2.25+ | 1.6+ | 7.64+ | Last | ✅ Complet |
| Alpine Linux | 5.0+ | 2.25+ | 1.6+ | 7.68+ | Last | ⚠️ Requiert setup |

## Notes importantes

- Le script utilise l'API GitHub pour récupérer la liste des dépôts
- Par défaut, les forks sont **inclus**. Utilisez `--exclude-forks` pour les exclure
- Il crée automatiquement le répertoire de destination s'il n'existe pas
- Il gère les erreurs et continue le traitement même si certains dépôts échouent
- Le cache API réduit les appels redondants (désactivable avec `--no-cache`)
- Le script vérifie automatiquement les prérequis avant l'exécution

## Limitations

- Ce script fonctionne uniquement sur les systèmes Unix/Linux/macOS (nécessite bash 4.0+)
- Il définit un délai d'expiration de 30 secondes par défaut pour les commandes git (configurable via `--timeout`)
- Le mode parallèle nécessite GNU parallel

## Problèmes courants et solutions

### Erreur "jq command not found"

**Solution** : Installer jq selon votre système d'exploitation :

```bash
# Ubuntu/Debian
sudo apt-get update && sudo apt-get install -y jq

# CentOS/RHEL
sudo yum install -y jq

# macOS
brew install jq
```

### Erreur "git command not found"

**Solution** : Installer git selon votre système d'exploitation :

```bash
# Ubuntu/Debian
sudo apt-get update && sudo apt-get install -y git

# CentOS/RHEL
sudo yum install -y git

# macOS
brew install git
```

### Erreur "curl command not found"

**Solution** : Installer curl selon votre système d'exploitation :

```bash
# Ubuntu/Debian
sudo apt-get update && sudo apt-get install -y curl

# CentOS/RHEL
sudo yum install -y curl

# macOS
brew install curl
```

### Erreur "Permission denied" lors du clonage

**Solution** : Vérifier les permissions et corriger si nécessaire :

```bash
# Vérifier les permissions du répertoire de destination
ls -la ./repositories

# Corriger les permissions
chmod 755 ./repositories
chown -R $USER:$USER ./repositories
```

### Erreur "Repository not found"

**Causes possibles** :

- Nom d'utilisateur ou d'organisation incorrect
- Dépôt privé sans authentification
- Dépôt supprimé ou déplacé

**Solution** :

```bash
# Pour les dépôts privés, utiliser l'authentification
export GITHUB_TOKEN="ghp_xxxxxxxxxxxx"
./git-mirror.sh users ZarTek-Creole

# Vérifier le nom d'utilisateur sur GitHub
curl https://api.github.com/users/ZarTek-Creole
```

### Erreur "API rate limit exceeded"

**Information** :

- Sans token : 60 requêtes/heure (rate limit API publique)
- Avec token : 5000 requêtes/heure (rate limit API authentifié)

**Solution** :

```bash
# Configurer un token GitHub
export GITHUB_TOKEN="ghp_xxxxxxxxxxxx"
./git-mirror.sh users ZarTek-Creole

# Vérifier votre usage actuel
curl -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/rate_limit
```

### Erreur "fatal: destination path already exists"

**Cause** : Un clone précédent a été interrompu

**Solution** : Le script gère automatiquement ce cas depuis v2.0. Si le problème persiste :

```bash
# Nettoyer manuellement si nécessaire
rm -rf ./repositories/problematic-repo

# Relancer le script
./git-mirror.sh users ZarTek-Creole
```

### Erreur de submodules en mode shallow

**Cause** : Les submodules ne sont pas supportés en mode shallow clonage

**Solution** : Automatiquement géré par le script

```bash
# Avec --depth, les submodules sont désactivés automatiquement
./git-mirror.sh --depth 1 users ZarTek-Creole

# Pour activer les submodules, utiliser sans --depth
./git-mirror.sh users ZarTek-Creole
```

### Erreur "parallel command not found"

**Cause** : GNU parallel n'est pas installé

**Solution** : Installer GNU parallel :

```bash
# Ubuntu/Debian
sudo apt-get install -y parallel

# CentOS/RHEL
sudo yum install -y parallel

# macOS
brew install parallel
```

**Alternative** : Utiliser sans parallélisation (plus lent) :

```bash
./git-mirror.sh users ZarTek-Creole
# Ou explicitement
./git-mirror.sh --parallel 1 users ZarTek-Creole
```

## Contributions

### Comment contribuer

1. Fork le projet
2. Créer une branche pour votre fonctionnalité (`git checkout -b feature/AmazingFeature`)
3. Commit vos changements (`git commit -m 'Add some AmazingFeature'`)
4. Push vers la branche (`git push origin feature/AmazingFeature`)
5. Ouvrir une Pull Request

## Licence

Ce projet est sous licence MIT. Voir le fichier [LICENSE](LICENSE) pour plus de détails.

## Auteur

- **ZarTek-Creole** - *Travail initial* - [GitHub](https://github.com/ZarTek-Creole)

## Donations

Si ce projet vous a aidé et que vous souhaitez le soutenir, vous pouvez faire un don via les plateformes suivantes :

- **GitHub Sponsors** : [Soutenir sur GitHub](https://github.com/sponsors/ZarTek-Creole)
- **Ko-fi** : [Faire un don sur Ko-fi](https://ko-fi.com/zartek)

Votre soutien est grandement apprécié et aide à continuer à développer et améliorer ce projet !

---

**Note** : Ce script est fourni tel quel, sans garantie. Utilisez-le à vos propres risques.
