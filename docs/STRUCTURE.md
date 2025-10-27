# Structure du Projet Git Mirror v2.0.0

## 📁 Organisation des Fichiers

```text
git-mirror/
├── git-mirror.sh                    # Script principal (~915 lignes)
│   └── Facade orchestrant tous les modules
│
├── README.md                        # Documentation principale complète
├── CONTRIBUTING.md                  # Guide de contribution
├── LICENSE                          # Licence MIT
│
├── config/
│   └── config.sh                   # Configuration centralisée
│       ├── Chemins par défaut
│       ├── Options Git
│       ├── Variables d'environnement
│       └── Paramètres globaux
│
├── lib/                            # Modules fonctionnels (12 modules)
│   ├── logging/
│   │   └── logger.sh              # Système de logging avec couleurs
│   │
│   ├── auth/
│   │   └── auth.sh                # Authentification multi-méthodes
│   │       ├── Token GitHub
│   │       ├── Clés SSH
│   │       └── Mode public
│   │
│   ├── api/
│   │   └── github_api.sh         # API GitHub
│   │       ├── Pagination
│   │       ├── Rate limiting
│   │       ├── Cache
│   │       └── Types de dépôts
│   │
│   ├── git/
│   │   └── git_ops.sh            # Opérations Git
│   │       ├── Clone
│   │       ├── Pull
│   │       ├── Submodules
│   │       └── Statistiques
│   │
│   ├── cache/
│   │   └── cache.sh              # Cache API
│   │       ├── TTL configurable
│   │       └── Invalidation
│   │
│   ├── filters/
│   │   └── filters.sh            # Filtrage avancé
│   │       ├── Patterns glob
│   │       ├── Inclusion/Exclusion
│   │       └── Fichiers de patterns
│   │
│   ├── parallel/
│   │   └── parallel.sh           # Parallélisation
│   │       ├── GNU parallel
│   │       └── Agrégation résultats
│   │
│   ├── metrics/
│   │   └── metrics.sh            # Métriques
│   │       ├── Export JSON
│   │       ├── Export CSV
│   │       └── Export HTML
│   │
│   ├── interactive/
│   │   └── interactive.sh        # Mode interactif
│   │
│   ├── state/
│   │   └── state.sh              # Gestion d'état
│   │       └── Mode resume
│   │
│   ├── incremental/
│   │   └── incremental.sh        # Mode incrémental
│   │       └── Based on pushed_at
│   │
│   └── profiling/
│       └── profiling.sh           # Profiling
│
├── tests/                          # Tests
│   └── unit/
│       └── test_filters_new.bats # Tests Bats
│
├── docs/                           # Documentation
│   ├── ARCHITECTURE.md            # Architecture du projet
│   └── STRUCTURE.md              # Ce fichier
│
├── reports/                        # Rapports
│   ├── CONSOLIDATED-FINAL-REPORT.md  # Rapport consolidé
│   ├── option-exclude-forks-final.md  # Option --exclude-forks
│   ├── git-mirror-fixes-summary.md    # Corrections
│   ├── git-mirror-parallel-issues-analysis.md  # Problèmes parallèles
│   ├── missing-repos-analysis.md       # Dépôts manquants
│   ├── test-repo-types-validation.md   # Validation repo-type
│   │
│   ├── phase1/                    # Rapports Phase 1
│   │   ├── audit-summary.md
│   │   ├── validation-finale.md
│   │   └── ...
│   │
│   └── phase2/                    # Rapports Phase 2
│       ├── api-fix-documentation.md
│       ├── filters-audit-complet.md
│       ├── git_ops-audit-complet.md
│       └── ...
│
├── .git-mirror-cache/             # Cache (généré, pas dans Git)
│   ├── api/                       # Cache API
│   └── metadata/                  # Métadonnées
│
└── .gitignore                     # Fichiers ignorés
```

## 📊 Statistiques du Projet

### Fichiers Principaux
| Fichier | Lignes | Description |
|---------|--------|-------------|
| `git-mirror.sh` | ~915 | Script principal (facade) |
| `config/config.sh` | ~100 | Configuration |
| Total modules `lib/` | ~3000+ | 12 modules fonctionnels |

### Distribution du Code
```
Configuration  : ~3%
Orchestration  : ~25%
Modules        : ~70%
Documentation  : ~2%
```

## 🔑 Points Clés

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
# ... etc
```

### Variables d'Environnement
- Chargées depuis `config/config.sh`
- Surchargées par les arguments CLI
- Exportées pour les sous-processus

### Chemins Absolus
- Tous les chemins sont normalisés en absolus
- Nécessaire pour le mode parallèle
- Empêche les erreurs "Invalid path"

## ✅ Nettoyage Effectué

### Fichiers Supprimés
- `reports/test-results-final.md` → Consolidé
- `reports/tests-final-results.md` → Consolidé
- `reports/final-report-100-percent.md` → Consolidé
- `reports/validation-complete-summary.md` → Consolidé
- `reports/final-analysis.md` → Consolidé

### Fichiers Conservés
- `reports/CONSOLIDATED-FINAL-REPORT.md` : Rapport final unique
- `reports/option-exclude-forks-final.md` : Documentation option
- `reports/git-mirror-fixes-summary.md` : Historique des corrections
- `reports/phase1/` et `phase2/` : Rapports d'audit historiques

## 🎯 Bonnes Pratiques

### Nommage
- Modules : `MODULE_NAME.sh`
- Fonctions : `module_function_name()`
- Variables locales : `local_var`
- Variables globales : `GLOBAL_VAR`

### Documentation
- Commentaires JSDoc-style pour fonctions
- README.md pour utilisateurs
- ARCHITECTURE.md pour développeurs
- STRUCTURE.md pour compréhension du projet

### Tests
- Un fichier de test par module
- Tests unitaires dans `tests/unit/`
- Utilisation de Bats framework

---

**Version** : 2.0.0  
**Date** : 2025-10-27  
**Status** : Production Ready
