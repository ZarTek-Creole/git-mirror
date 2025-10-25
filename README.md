# Git Mirror

## Résumé

Ce script permet de mettre à jour tous les dépôts d'un utilisateur ou d'une
organisation sur GitHub. Il utilise l'API GitHub et l'outil jq pour récupérer
la liste des dépôts et exécute la commande git clone ou git pull sur chaque
dépôt.

## Description

Ce script permet de cloner ou mettre à jour tous les dépôts GitHub (qui ne
sont pas des forks) appartenant à un utilisateur ou une organisation donnée.
Il utilise l'API GitHub et l'outil jq pour récupérer la liste des dépôts et
exécute la commande git clone ou git pull sur chaque dépôt. Le script définit
également un délai d'expiration de 30 secondes pour la commande git afin
d'éviter les exécutions de commandes interminables.

## Dépendances & Prérequis

Pour utiliser ce script, vous devez avoir les outils suivants installés sur
votre ordinateur :

- jq (version 1.5 ou supérieure) : outil de manipulation de JSON en ligne de
  commande. Vous pouvez l'installer en exécutant la commande suivante :
  - Ubuntu/Debian : `sudo apt-get install jq`
  - CentOS/Fedora : `sudo yum install jq`
  - MacOS : `brew install jq`
  - Si aucun de ces gestionnaires de paquets n'est disponible, vous pouvez
    télécharger l'archive de jq depuis le site officiel
    [jq](https://stedolan.github.io/jq/) et l'installer manuellement.

- git (version 2.9 ou supérieure) : outil de gestion de versions. Vous pouvez
  l'installer en exécutant la commande suivante :
  - Ubuntu/Debian : `sudo apt-get install git`
  - CentOS/Fedora : `sudo yum install git`
  - MacOS : `brew install git`
  - Si aucun de ces gestionnaires de paquets n'est disponible, vous pouvez
    télécharger l'installateur de git depuis le site officiel
    [Git](https://git-scm.com/downloads) et l'exécuter.

- curl (version 7.68 ou supérieure) : outil de transfert de données. Vous
  pouvez l'installer en exécutant la commande suivante :
  - Ubuntu/Debian : `sudo apt-get install curl`
  - CentOS/Fedora : `sudo yum install curl`
  - MacOS : `brew install curl`
  - Si aucun de ces gestionnaires de paquets n'est disponible, vous pouvez
    télécharger l'installateur de curl depuis le site officiel
    [curl](https://curl.haxx.se/download.html) et l'exécuter.

## Utilisation

### Syntaxe

```bash
./git-mirror.sh [OPTIONS] context username_or_orgname
```

### Arguments

- `context` : Type de contexte (users ou orgs)
- `username_or_orgname` : Nom d'utilisateur ou d'organisation GitHub

### Options

- `-d, --destination DIR` : Répertoire de destination (défaut: ./repositories)
- `-b, --branch BRANCH` : Branche spécifique à cloner (défaut: branche par défaut)
- `-f, --filter FILTER` : Filtre Git pour le clonage partiel (ex: blob:none)
- `-n, --no-checkout` : Cloner sans checkout initial
- `-s, --single-branch` : Cloner une seule branche
- `--depth DEPTH` : Profondeur du clonage shallow (défaut: 1)
- `--timeout SECONDS` : Timeout pour les opérations Git (défaut: 30)
- `--parallel JOBS` : Nombre de jobs parallèles (défaut: 1, nécessite GNU parallel)
- `--resume` : Reprendre une exécution interrompue
- `--incremental` : Mode incrémental (traite seulement les repos modifiés)
- `--exclude PATTERN` : Exclure les repos correspondant au pattern (peut être
  utilisé plusieurs fois)
- `--exclude-file FILE` : Lire les patterns d'exclusion depuis un fichier
- `--include PATTERN` : Inclure uniquement les repos correspondant au pattern
  (peut être utilisé plusieurs fois)
- `--include-file FILE` : Lire les patterns d'inclusion depuis un fichier
- `--metrics FILE` : Exporter les métriques vers un fichier (formats: json,csv,html)
- `--interactive` : Mode interactif avec confirmations
- `--confirm` : Afficher un résumé et demander confirmation avant de commencer
- `--yes, -y` : Mode automatique (ignorer toutes les confirmations)
- `-v, --verbose` : Mode verbeux (peut être utilisé plusieurs fois: -vv, -vvv)
- `-q, --quiet` : Mode silencieux (sortie minimale)
- `--dry-run` : Simulation sans actions réelles
- `--skip-count` : Éviter le calcul du nombre total de dépôts (utile si limite API)
- `-h, --help` : Afficher cette aide

### Exemples

```bash
# Cloner tous les dépôts d'un utilisateur
./git-mirror.sh users ZarTek-Creole

# Cloner dans un répertoire spécifique
./git-mirror.sh -d /path/to/repos users ZarTek-Creole

# Cloner avec des options avancées
./git-mirror.sh -b main -f blob:none users ZarTek-Creole

# Cloner une organisation avec options
./git-mirror.sh -s -n --depth 5 orgs microsoft

# Mode dry-run avec verbose
./git-mirror.sh --dry-run -vv users microsoft

# Mode silencieux
./git-mirror.sh -q users microsoft

# Reprendre une exécution interrompue
./git-mirror.sh --resume users microsoft

# Mode incrémental
./git-mirror.sh --incremental users microsoft
```

### Dépendances

- **Obligatoires** : git >= 2.25, jq >= 1.6, curl >= 7.68
- **Optionnelles** : GNU parallel (pour --parallel), SSH keys (pour auth SSH)

### Variables d'environnement

- `GITHUB_TOKEN` : Token d'accès personnel GitHub
- `GITHUB_SSH_KEY` : Chemin vers la clé SSH privée
- `GITHUB_AUTH_METHOD` : Force la méthode d'authentification (token/ssh/public)

## Limitations

- Ce script ne fonctionne que sur les systèmes Unix/Linux/macOS (nécessite bash
  4.0+)
- Il définit un délai d'expiration de 30 secondes pour la commande git afin
  d'éviter les exécutions de commandes interminables
- Il définit un délai d'expiration de 30 secondes pour la commande git afin
  d'éviter les exécutions de commandes interminables
- Il définit un délai d'expiration de 30 secondes pour la commande git afin
  d'éviter les exécutions de commandes interminables

## Options de configuration

### Exemples de commandes

```bash
# Cloner tous les dépôts d'un utilisateur
./git-mirror.sh users ZarTek-Creole

# Cloner dans un répertoire spécifique
./git-mirror.sh -d /path/to/repos users ZarTek-Creole

# Cloner avec des options avancées
./git-mirror.sh -b main -f blob:none users ZarTek-Creole
```

## Notes

- Le script utilise l'API GitHub pour récupérer la liste des dépôts
- Il ignore automatiquement les dépôts qui sont des forks
- Il crée automatiquement le répertoire de destination s'il n'existe pas
- Il gère les erreurs et continue le traitement même si certains dépôts échouent

## Contributions

### Améliorer la documentation

- Ajouter de nouvelles fonctionnalités
- Corriger des bugs
- Améliorer les performances

### Comment contribuer

1. Fork le projet
2. Créer une branche pour votre fonctionnalité (`git checkout -b feature/AmazingFeature`)
3. Commit vos changements (`git commit -m 'Add some AmazingFeature'`)
4. Push vers la branche (`git push origin feature/AmazingFeature`)
5. Ouvrir une Pull Request

## Problèmes courants et solutions connues

### Erreur "jq command not found"

**Solution** : Installer jq selon votre système d'exploitation (voir section
Dépendances)

### Erreur "git command not found"

**Solution** : Installer git selon votre système d'exploitation (voir section
Dépendances)

### Erreur "curl command not found"

**Solution** : Installer curl selon votre système d'exploitation (voir section
Dépendances)

### Erreur "Permission denied" lors du clonage

**Solution** : Vérifier que vous avez les permissions d'écriture dans le
répertoire de destination

### Erreur "Repository not found"

**Solution** : Vérifier que le nom d'utilisateur ou d'organisation est correct
et que les dépôts sont publics ou que vous avez les permissions d'accès

### Erreur "API rate limit exceeded"

**Solution** : Attendre que la limite de taux soit réinitialisée ou utiliser un
token GitHub pour augmenter la limite

## Licence

Ce projet est sous licence MIT. Voir le fichier [LICENSE](LICENSE) pour plus
de détails.

## Auteur

- **ZarTek-Creole** - *Travail initial* -
  [GitHub](https://github.com/ZarTek-Creole)

## Donations

Si ce projet vous a aidé et que vous souhaitez le soutenir, vous pouvez faire
un don via les plateformes suivantes :

- **GitHub Sponsors** :
  [Soutenir sur GitHub](https://github.com/sponsors/ZarTek-Creole)
- **Ko-fi** : [Faire un don sur Ko-fi](https://ko-fi.com/zartek)

Votre soutien est grandement apprécié et m'aide à continuer à développer et
améliorer ce projet !

---

**Note** : Ce script est fourni tel quel, sans garantie. Utilisez-le à vos
propres risques.
