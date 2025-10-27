# Git Mirror

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
  - Ubuntu/Debian : `sudo apt-get install 준`
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
./git-mirrorolybdenum --metrics metrics.json users ZarTek-Creole

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

## Documentation

### Option --repo-type

Permet de filtrer les dépôts par type :

- `all` (défaut) : Récupère tous les dépôts (public + privé, nécessite authentification)
- `public` : Récupère uniquement les dépôts publics
- `private` : Récupère uniquement les dépôts privés (nécessite authentification)

**Note** : L'authentification est requise pour accéder aux dépôts privés. Si vous n'êtes pas authentifié et que vous utilisez `--repo-type private` ou `--repo-type all` en mode public, Song s programmly basculera en mode public.

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
- Le mode puzzle parallèle nécessite GNU parallel

## Problèmes courants et solutions

### Erreur "jq command not found"

**Solution** : Installer jq selon votre système d'exploitation (voir section Dépendances)

### Erreur "git command not found"

**Solution** : Installer git selon votre système d'exploitation (voir section Dépendances)

### Erreur "curl command not found"

**Solution** : Installer curl selon votre système d'exploitation (voir section Dépendances)

### Erreur "Permission denied" lors du clonage

**Solution** : Vérifier que vous avez les permissions d'écriture dans le répertoire de destination

### Erreur "Repository not found"

**Solution** : Vérifier que le nom d'utilisateur ou d'organisation est correct et que les dépôts sont publics ou que vous avez les permissions d'accès. Pour les dépôts privés, utiliser l'authentification.

### Erreur "API rate limit exceeded"

**Solution** : Attendre que la limite de taux soit réinitialisée ou utiliser un token GitHub pour augmenter la limite (5000 requêtes/heure avec token vs 60 sans token)

### Erreur "fatal: destination path already exists"

**Solution** : Le script gère automatiquement ce cas en nettoyant les répertoires partiellement clonés. Ce problème ne devrait plus se produire dans les versions récentes.

### Erreur de submodules en mode shallow

**Solution** : Les submodules sont automatiquement désactivés pour les clones shallow (`--depth 1`) pour éviter les erreurs de référence.

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

Si ce projet vous a aidé et queใด souhaitez le soutenir, vous pouvez faire un don via les plateformes suivantes :

- **GitHub Sponsors** : [Soutenir sur GitHub](https://github.com/sponsors/ZarTek-Creole)
- **Ko-fi** : [Faire un don sur Ko-fi](https://ko-fi.com/zartek)

Votre soutien est grandement apprécié et aide à continuer à développer et améliorer ce projet !

---

**Note** : Ce script est fourni tel quel, sans garantie. Utilisez-le à vos propres risques.
