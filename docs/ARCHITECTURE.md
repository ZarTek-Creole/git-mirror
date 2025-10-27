# Architecture Git Mirror v2.0.0

## 📁 Structure du Projet

```text
git-mirror/
├── git-mirror.sh                    # Script principal (modulaire, ~928 lignes)
├── README.md                        # Documentation principale
├── CONTRIBUTING.md                  # Guide de contribution
├── LICENSE                          # Licence MIT
│
├── config/                          # Configuration
│   ├── config.sh                   # Configuration centralisée
│   ├── git-mirror.conf            # Config par défaut
│   ├── performance.conf           # Config performance
│   ├── security.conf              # Config sécurité
│   ├── cicd.conf                  # Config CI/CD
│   ├── ci.conf                    # Config CI
│   ├── deployment.conf            # Config déploiement
│   ├── testing.conf               # Config tests
│   ├── maintenance.conf           # Config maintenance
│   ├── dependencies.conf          # Gestion dépendances
│   ├── documentation.conf         # Config documentation
│   └── docs.conf                  # Config docs
│
├── lib/                            # Modules fonctionnels
│   ├── logging/
│   │   └── logger.sh              # Système de logging
│   ├── auth/
│   │   └── auth.sh                # Authentification (token, SSH, public)
│   ├── api/
│   │   └── github_api.sh         # API GitHub (pagination, cache, rate limits)
│   ├── git/
│   │   └── git_ops.sh            # Opérations Git (clone, pull, stats)
│   ├── cache/
│   │   └── cache.sh              # Cache API avec TTL
│   ├── filters/
│   │   └── filters.sh            # Filtrage par patterns
│   ├── parallel/
│   │   └── parallel.sh           # Parallélisation avec GNU parallel
│   ├── metrics/
│   │   └── metrics.sh            # Métriques et statistiques
│   ├── interactive/
│   │   └── interactive.sh        # Mode interactif
│   ├── state/
│   │   └── state.sh              # Gestion d'état (resume)
│   ├── incremental/
│   │   └── incremental.sh        # Mode incrémental
│   ├── utils/
│   │   └── profiling.sh           # Profiling de performance
│   └── validation/
│       └── validation.sh          # Validation des entrées
│
├── tests/                          # Tests (7 catégories)
│   ├── unit/                      # Tests unitaires (13 fichiers .bats)
│   ├── integration/               # Tests d'intégration
│   ├── regression/                # Tests de régression
│   ├── load/                      # Tests de charge
│   ├── mocks/                     # Données mockées
│   └── utils/                     # Utilitaires de test
│
├── docs/                           # Documentation technique
│   └── ARCHITECTURE.md            # Ce fichier (architecture complète)
│
├── reports/                        # Rapports d'analyse (historiques)
│
├── .git-mirror-cache/             # Cache API (généré)
│   ├── api/
│   └── metadata/
│
└── .gitignore                     # Fichiers ignorés par Git
```

## 🔄 Architecture Modulaire ✅
- **Fichier principal** : `git-mirror.sh` (~928 lignes, facade pattern)
- **Modules** : 13 modules spécialisés dans `lib/`
- **Configuration** : Centralisée dans `config/`
- **Tests** : Suite de tests Bats
- **Avantages** : Maintenable, testable, extensible

## 🏗️ Architecture Modulaire

### Pattern Facade
Le script principal `git-mirror.sh` agit comme une facade, orchestrant les appels aux modules spécialisés.

### Modules Principaux

#### 1. Logging (`lib/logging/logger.sh`)
- Système de logs colorés
- Niveaux : DEBUG, INFO, WARN, ERROR, FATAL
- Support de verbosité multiple (-v, -vv, -vvv)
- Format : `[LEVEL] timestamp - message`

#### 2. Authentication (`lib/auth/auth.sh`)
- Support multi-méthodes : Token, SSH, Public
- Détection automatique de la méthode disponible
- Variables d'environnement :
  - `GITHUB_TOKEN`
  - `GITHUB_SSH_KEY`
  - `GITHUB_AUTH_METHOD`

#### 3. GitHub API (`lib/api/github_api.sh`)
- Gestion de la pagination
- Cache avec TTL configurable
- Rate limiting
- Support `/user/repos` (authentifié) et `/users/:username/repos` (public)
- Filtrage par type : all, public, private

#### 4. Git Operations (`lib/git/git_ops.sh`)
- Clone avec retry automatique
- Nettoyage des clones partiels
- Gestion des submodules
- Support des filtres Git (blob:none, etc.)
- Clonage shallow (--depth)
- Statistiques Git

#### 5. Cache (`lib/cache/cache.sh`)
- Cache API avec système de fichiers
- TTL configurable par défaut (1 heure)
- Invalidation manuelle (--no-cache)
- Cache pour métadonnées (total_repos)

#### 6. Filters (`lib/filters/filters.sh`)
- Exclusion par patterns
- Inclusion par patterns
- Support de fichiers de patterns
- Pattern glob (`*`, `?`, `[...]`)
- Filtrage par type de dépôt (fork/non-fork)

#### 7. Parallel (`lib/parallel/parallel.sh`)
- Utilisation de GNU parallel
- Jobs parallèles configurables (--parallel)
- Agrégation des résultats
- Gestion des erreurs en parallèle
- Export des variables d'environnement

#### 8. Metrics (`lib/metrics/metrics.sh`)
- Collecte de métriques
- Export JSON, CSV, HTML
- Statistiques : succès, échecs, temps
- Rate de réussite

#### 9. Interactive (`lib/interactive/interactive.sh`)
- Mode interactif avec confirmations
- Résumé avant exécution
- Mode automatique (--yes)

#### 10. State (`lib/state/state.sh`)
- Sauvegarde d'état pour reprise
- Persistance des dépôts traités
- Mode --resume

#### 11. Incremental (`lib/incremental/incremental.sh`)
- Traitement uniquement des dépôts modifiés
- Basé sur `pushed_at`
- Cache de dernière synchronisation

#### 12. Profiling (`lib/utils/profiling.sh`)
- Mesure de performance
- Détails par fonction
- Export des stats

#### 13. Validation (`lib/validation/validation.sh`)
- Validation des entrées utilisateur
- Vérification des paramètres
- Helpers de validation

## 🔧 Options Principales

### Filtrage
- `--repo-type TYPE` : all, public, private
- `--exclude-forks` : Exclure les forks
- `--exclude PATTERN` : Exclure par pattern
- `--include PATTERN` : Inclure par pattern

### Performance
- `--parallel JOBS` : Jobs parallèles
- `--incremental` : Seulement les modifiés
- `--depth N` : Clonage shallow
- `--filter FILTER` : Filtre Git

### Opérations
- `--resume` : Reprendre une exécution
- `--interactive` : Mode interactif
- `--yes` : Mode automatique
- `--dry-run` : Simulation

## 🎯 Workflows Principaux

### 1. Workflow Standard
```
1. Parse arguments
2. Load configuration
3. Authenticate
4. Fetch repositories from API
5. Apply filters
6. Process repositories (clone/pull)
7. Generate report
```

### 2. Workflow Parallèle
```
1. Parse arguments
2. Load modules
3. Authenticate
4. Fetch repositories
5. Apply filters
6. Split into jobs
7. Execute parallel
8. Aggregate results
9. Generate report
```

### 3. Workflow Incrémental
```
1. Parse arguments
2. Load last sync timestamp
3. Fetch repositories
4. Filter by pushed_at > last_sync
5. Process only modified repos
6. Update last_sync timestamp
7. Generate report
```

## 📊 Métriques Clés

### Statistiques du Code
| Fichier | Lignes | Description |
|---------|--------|-------------|
| `git-mirror.sh` | 928 | Script principal (facade) |
| `config/config.sh` | 330 | Configuration principale |
| Total modules `lib/` | 3905 | 13 modules fonctionnels |
| Fichiers de config `.conf` | 12 | Configuration spécialisée |
| **Total** | **5163+** | Lignes de code |

### Distribution du Code
```
Configuration  : 330 lignes  (~6%)  + 12 fichiers .conf
Orchestration  : 928 lignes  (~18%)
Modules        : 3905 lignes (~76%)
```

### Structure des Tests
- **Tests unitaires** : 13 fichiers `.bats`
- **Catégories de tests** : 7 (unit, integration, regression, load, mocks, utils, data)
- **Framework** : Bats (Bash Automated Testing System)

### Performance
- **Taux de succès** : 98%+
- **Performance parallèle** : 5x accélération avec 5 jobs
- **Cache hit rate** : 90%+ avec TTL 1h
- **Temps d'exécution** : 15-20 min pour 249 dépôts en parallèle

## 🔑 Points Clés d'Implémentation

### Séparation des Responsabilités
- **git-mirror.sh** : Orchestration uniquement
- **lib/** : Logique métier
- **config/** : Configuration
- **tests/** : Tests

### Imports de Modules
```bash
# Dans git-mirror.sh
source "${SCRIPT_DIR}/config/config.sh"
source "${SCRIPT_DIR}/lib/logging/logger.sh"
source "${SCRIPT_DIR}/lib/auth/auth.sh"
# ... etc (13 modules au total)
```

### Variables d'Environnement
- Chargées depuis `config/config.sh`
- Surchargées par les arguments CLI
- Exportées pour les sous-processus

### Chemins Absolus
- Tous les chemins sont normalisés en absolus
- Nécessaire pour le mode parallèle
- Empêche les erreurs "Invalid path"

## 📁 Fichiers de Configuration

Le projet utilise 12 fichiers de configuration spécialisés dans `config/` :

### Configuration Principale
- **config.sh** : Configuration centralisée (330 lignes)
  - Variables d'environnement
  - Chemins et répertoires
  - Options par défaut

### Configurations Spécialisées
- **git-mirror.conf** : Configuration par défaut du script
  - Paramètres généraux (destination, branche, filtre)
  - Configuration des modules (parallel, metrics, cache)
  - Gestion des logs et verbose

- **performance.conf** : Optimisation des performances
  - Paramètres de parallélisation (DEFAULT_JOBS, MAX_JOBS, TIMEOUT)
  - Configuration du cache (TTL, cleanup intervals)
  - Gestion mémoire et réseau

- **security.conf** : Configuration de sécurité
  - Gestion des tokens
  - Validation des accès
  - Paramètres d'authentification

- **cicd.conf / ci.conf** : Configuration CI/CD
  - Plateforme et triggers
  - Matrices de tests multi-OS
  - Caching et optimisation

- **deployment.conf** : Déploiement
  - Environnements cibles
  - Scripts de déploiement
  - Rollback strategies

- **testing.conf** : Configuration des tests
  - Types de tests
  - Environnements de test
  - Mocking et fixtures

- **maintenance.conf** : Maintenance
  - Tâches périodiques
  - Cleanup automatique
  - Rapports de santé

- **dependencies.conf** : Gestion des dépendances
  - Versions requises
  - Compatibilité
  - Mises à jour

- **documentation.conf / docs.conf** : Documentation
  - Génération de docs
  - Formats de sortie
  - Templates

## 🎨 Design Patterns Appliqués

### 1. Pattern Facade
**Implémentation** : `git-mirror.sh` agit comme une façade
- **Rôle** : Interface unique simplifiée vers 13 modules complexes
- **Avantage** : Cachage de la complexité interne
- **Usage** : Orchestration des appels aux modules

### 2. Pattern Command
**Implémentation** : Arguments CLI → Actions
- **Role** : Encapsulation des commandes comme objets
- **Avantage** : Flexibilité et extensibilité
- **Usage** : `--parallel`, `--incremental`, `--resume`

### 3. Pattern Strategy
**Implémentation** : Authentification multi-méthodes
- **Role** : Interchangeabilité des algorithmes
- **Méthodes** : Token, SSH, Public
- **Avantage** : Extensible pour nouvelles méthodes

### 4. Pattern Observer
**Implémentation** : Système de logging/métriques
- **Role** : Notification des changements d'état
- **Observers** : Logger, Métriques, Profiling
- **Avantage** : Découplage des notifications

### 5. Pattern Template Method
**Implémentation** : Workflows standardisés
- **Workflows** : Standard, Parallèle, Incrémental
- **Avantage** : Réutilisation de logique commune
- **Extensibilité** : Nouveaux workflows faciles à ajouter

### 6. Pattern Singleton
**Implémentation** : Configuration globale
- **Instance unique** : Chargement une seule fois
- **Variables globales** : `SCRIPT_DIR`, `LIB_DIR`, `CONFIG_DIR`
- **Avantage** : Cohérence de configuration

## 🎯 Bonnes Pratiques

### Nommage
- Modules : `MODULE_NAME.sh`
- Fonctions : `module_function_name()`
- Variables locales : `local_var`
- Variables globales : `GLOBAL_VAR`

### Tests
- 7 catégories de tests organisées dans `tests/`
- 13 fichiers `.bats` pour tests unitaires
- Utilisation de Bats framework
- Tests d'intégration, régression et charge

## 🔐 Sécurité

- Gestion sécurisée des tokens
- Pas de logs de secrets
- Détection automatique des fuites
- Validation des chemins

## 🧪 Tests

- Tests unitaires Bats
- Tests d'intégration
- Tests de charge
- Validation ShellCheck

## 🔍 Guide de Debugging pour Développeurs

### Mode Débogage
```bash
# Activer le mode verbeux maximum
./git-mirror.sh -vvv users ZarTek-Creole

# Activer le profiling
./git-mirror.sh --profile users ZarTek-Creole
```

### Variables d'Environnement de Debug
```bash
export DEBUG=true
export VERBOSE=3
export LOG_LEVEL=DEBUG
```

### Points d'Inspection
1. **Logger** : Vérifier les logs avec `-vvv`
2. **Cache** : Vérifier `$CACHE_DIR/api/`
3. **État** : Vérifier `$STATE_FILE` ou `$STATE_DIR/`
4. **Métriques** : Exporter avec `--metrics debug.json`

### Problèmes Courants

#### Erreur "Module not found"
```bash
# Vérifier que tous les modules sont chargés
source lib/logging/logger.sh
```

#### Erreur "Invalid path" en mode parallèle
```bash
# Vérifier normalisation des chemins
ls -la $SCRIPT_DIR
```

#### Problème de cache
```bash
# Désactiver le cache temporairement
./git-mirror.sh --no-cache users ZarTek-Creole

# Nettoyer le cache
rm -rf .git-mirror-cache
```

## 📈 Évolutions Futures

- Support GitLab
- Support Bitbucket
- Mode daemon (surveillance continue)
- Interface web
- Notifications

---

**Note** : Cette architecture modulaire facilite la maintenance, les tests et l'extension du projet. Chaque module peut être développé, testé et débogué indépendamment.
