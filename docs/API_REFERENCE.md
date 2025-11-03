# Référence API - Git Mirror

## Modules et Fonctions

### Module API (`lib/api/github_api.sh`)

#### `api_init()`
Initialise le module API GitHub.

#### `api_check_rate_limit()`
Vérifie les limites de taux API restantes.

**Retour**: 
- `0` si limite disponible
- `1` si limite atteinte

#### `api_wait_rate_limit()`
Attend que la limite de taux soit réinitialisée.

#### `api_cache_key(url)`
Génère une clé de cache pour une URL.

**Paramètres**:
- `url`: URL de l'API GitHub

**Retour**: Clé de cache (chaîne)

#### `api_cache_valid(cache_file, ttl)`
Vérifie si un fichier de cache est valide.

**Paramètres**:
- `cache_file`: Chemin vers le fichier de cache
- `ttl`: Time-to-live en secondes

**Retour**: 
- `0` si valide
- `1` si expiré ou invalide

#### `api_fetch_with_cache(url)`
Récupère des données depuis l'API avec cache.

**Paramètres**:
- `url`: URL de l'API GitHub

**Retour**: JSON (sur stdout)

#### `api_fetch_all_repos(context, username)`
Récupère tous les dépôts avec pagination automatique.

**Paramètres**:
- `context`: "users" ou "orgs"
- `username`: Nom d'utilisateur ou organisation

**Retour**: JSON array de dépôts (sur stdout)

#### `api_get_total_repos(context, username)`
Récupère le nombre total de dépôts.

**Paramètres**:
- `context`: "users" ou "orgs"
- `username`: Nom d'utilisateur ou organisation

**Retour**: Nombre total (sur stdout)

### Module Authentification (`lib/auth/auth.sh`)

#### `auth_init()`
Initialise le module d'authentification.

#### `auth_detect_method()`
Détecte automatiquement la méthode d'authentification disponible.

**Retour**: Nom de la méthode ("token", "ssh", "public")

#### `auth_validate_token(token)`
Valide un token GitHub.

**Paramètres**:
- `token`: Token GitHub à valider

**Retour**: 
- `0` si valide
- `1` si invalide

#### `auth_get_headers(method)`
Génère les en-têtes HTTP pour l'authentification.

**Paramètres**:
- `method`: Méthode d'authentification

**Retour**: Options curl pour les en-têtes (sur stdout)

#### `auth_transform_url(url)`
Transforme une URL HTTPS en SSH si nécessaire.

**Paramètres**:
- `url`: URL GitHub (HTTPS ou SSH)

**Retour**: URL transformée (sur stdout)

### Module Cache (`lib/cache/cache.sh`)

#### `init_cache(cache_dir, ttl, enabled)`
Initialise le système de cache.

**Paramètres**:
- `cache_dir`: Répertoire de cache (optionnel)
- `ttl`: Time-to-live en secondes (optionnel)
- `enabled`: Activer/désactiver le cache (optionnel)

#### `cache_get(key)`
Récupère une valeur depuis le cache.

**Paramètres**:
- `key`: Clé de cache

**Retour**: Valeur en JSON (sur stdout) ou erreur

#### `cache_set(key, value)`
Stocke une valeur dans le cache.

**Paramètres**:
- `key`: Clé de cache
- `value`: Valeur JSON à stocker

#### `cache_exists(key)`
Vérifie si une clé existe dans le cache.

**Paramètres**:
- `key`: Clé de cache

**Retour**: 
- `0` si existe et valide
- `1` si n'existe pas ou expiré

#### `cache_delete(key)`
Supprime une clé du cache.

**Paramètres**:
- `key`: Clé de cache

#### `cache_clear()`
Vide complètement le cache.

### Module Git Operations (`lib/git/git_ops.sh`)

#### `clone_repository(repo_url, dest_dir, options...)`
Clone un dépôt Git.

**Paramètres**:
- `repo_url`: URL du dépôt
- `dest_dir`: Répertoire de destination
- Options supplémentaires (branch, depth, etc.)

**Retour**: 
- `0` si succès
- `1` si échec

#### `update_repository(repo_path, branch)`
Met à jour un dépôt existant.

**Paramètres**:
- `repo_path`: Chemin vers le dépôt local
- `branch`: Branche à mettre à jour (optionnel)

**Retour**: 
- `0` si succès
- `1` si échec

#### `repository_exists(repo_path)`
Vérifie si un dépôt existe localement.

**Paramètres**:
- `repo_path`: Chemin vers le dépôt

**Retour**: 
- `0` si existe
- `1` si n'existe pas

### Module Filtrage (`lib/filters/filters.sh`)

#### `filters_init()`
Initialise le module de filtrage.

#### `filters_match_pattern(text, pattern)`
Vérifie si un texte correspond à un pattern.

**Paramètres**:
- `text`: Texte à vérifier
- `pattern`: Pattern (glob, regex, exact)

**Retour**: 
- `0` si correspond
- `1` si ne correspond pas

#### `filters_should_process(repo_json)`
Détermine si un dépôt doit être traité.

**Paramètres**:
- `repo_json`: Objet JSON du dépôt

**Retour**: 
- `0` si doit être traité
- `1` si doit être ignoré

#### `filters_filter_repos(repos_json)`
Filtre un tableau de dépôts.

**Paramètres**:
- `repos_json`: Tableau JSON de dépôts

**Retour**: Tableau JSON filtré (sur stdout)

### Module Métriques (`lib/metrics/metrics.sh`)

#### `metrics_init()`
Initialise le module de métriques.

#### `metrics_start()`
Démarre la collecte de métriques.

#### `metrics_stop()`
Arrête la collecte de métriques.

#### `metrics_record_repo(name, status, duration, size)`
Enregistre les métriques d'un dépôt.

**Paramètres**:
- `name`: Nom du dépôt
- `status`: Statut ("cloned", "updated", "failed")
- `duration`: Durée en secondes
- `size`: Taille en MB

#### `metrics_calculate()`
Calcule les métriques agrégées.

**Retour**: Métriques séparées par `|` (sur stdout)

#### `metrics_export_json(output_file)`
Exporte les métriques en JSON.

**Paramètres**:
- `output_file`: Fichier de sortie (optionnel, stdout si vide)

#### `metrics_export_csv(output_file)`
Exporte les métriques en CSV.

**Paramètres**:
- `output_file`: Fichier de sortie (optionnel, stdout si vide)

#### `metrics_export_html(output_file)`
Exporte les métriques en HTML.

**Paramètres**:
- `output_file`: Fichier de sortie (optionnel, stdout si vide)

### Module Parallèle (`lib/parallel/parallel.sh`)

#### `parallel_init()`
Initialise le module parallèle.

#### `parallel_execute(command, items, jobs)`
Exécute une commande en parallèle sur des items.

**Paramètres**:
- `command`: Commande à exécuter
- `items`: Liste d'items (une par ligne)
- `jobs`: Nombre de jobs parallèles

#### `parallel_clone_repos(repos, jobs)`
Clone des dépôts en parallèle.

**Paramètres**:
- `repos`: Liste de dépôts (une par ligne)
- `jobs`: Nombre de jobs parallèles

### Module État (`lib/state/state.sh`)

#### `state_init()`
Initialise le module d'état.

#### `state_save(context, username, dest, total, processed, failed, success, interrupted)`
Sauvegarde l'état actuel.

#### `state_load()`
Charge l'état précédent.

**Retour**: 
- `0` si chargé avec succès
- `1` si aucun état trouvé

#### `state_should_resume()`
Détermine si une reprise est nécessaire.

**Retour**: 
- `0` si doit reprendre
- `1` si nouvelle exécution

## Variables d'Environnement

### Authentification
- `GITHUB_TOKEN`: Token d'accès personnel GitHub
- `GITHUB_SSH_KEY`: Chemin vers la clé SSH privée
- `GITHUB_AUTH_METHOD`: Méthode forcée ("token", "ssh", "public")

### Configuration
- `GIT_MIRROR_DEST_DIR`: Répertoire de destination par défaut
- `GIT_MIRROR_CACHE_TTL`: TTL du cache en secondes
- `GIT_MIRROR_PARALLEL_JOBS`: Nombre de jobs parallèles par défaut

## Codes de Retour

- `0`: Succès
- `1`: Erreur générale
- `2`: Erreur de configuration
- `3`: Erreur d'authentification
- `4`: Erreur API
- `5`: Erreur Git

## Exemples d'Utilisation des Modules

### Exemple 1: Utiliser l'API

```bash
source lib/api/github_api.sh
api_init
repos=$(api_fetch_all_repos "users" "octocat")
echo "$repos" | jq '.[].name'
```

### Exemple 2: Utiliser le Cache

```bash
source lib/cache/cache.sh
init_cache ".cache" 3600 true
cache_set "key1" '{"data": "test"}'
value=$(cache_get "key1")
```

### Exemple 3: Utiliser les Métriques

```bash
source lib/metrics/metrics.sh
metrics_init
metrics_start
metrics_record_repo "repo1" "cloned" 10 5
metrics_stop
metrics_export_json "report.json"
```
