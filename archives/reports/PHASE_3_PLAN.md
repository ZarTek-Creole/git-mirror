# Phase 3 - Tests Complets - Plan Maximisation Couverture

**Date**: 2025-01-29  
**Objectif**: 90%+ de couverture  
**Statut Actuel**: 2.69% (113 lignes couvertes / 4198 lignes instrumentées)  
**Progression Cible**: 3779 lignes supplémentaires

## Analyse Actuelle

### Tests Existants
- ✅ test_validation_spec.sh : 53 tests (52 passent, 1 fail, 13 warnings)
- ⏳ test_logger_spec.sh : Présent mais non analysé
- ❌ test_git_ops_spec.sh : À vérifier
- ❌ test_api_*_spec.sh : À créer/améliorer
- ❌ test_auth_*_spec.sh : À créer/améliorer

### Modules à Tester (Priorité)

| Module | Lignes | Tests Existants | Couverture Est. | Priorité |
|--------|--------|-----------------|-----------------|----------|
| **validation.sh** | 359 | ✅ 53 tests | ~15% | 🟡 Moyenne |
| **git_ops.sh** | 441 | ⏳ Partiel | ~0% | 🔥 CRITIQUE |
| **github_api.sh** | 481 | ❌ 0 | ~0% | 🔥 CRITIQUE |
| **auth.sh** | 366 | ❌ 0 | ~0% | 🔥 CRITIQUE |
| **logger.sh** | 207 | ⏳ Partiel | ~5% | 🟡 Moyenne |
| **cache.sh** | 333 | ❌ 0 | ~0% | 🟢 Haute |
| **filters.sh** | ~300 | ⏳ Partiel | ~5% | 🟢 Haute |
| **parallel.sh** | ~200 | ❌ 0 | ~0% | 🟡 Moyenne |
| **metrics.sh** | ~200 | ❌ 0 | ~0% | 🟡 Moyenne |
| **incremental.sh** | ~200 | ❌ 0 | ~0% | 🟢 Moyenne |
| **interactive.sh** | ~200 | ❌ 0 | ~0% | 🟢 Faible |
| **state.sh** | ~200 | ❌ 0 | ~0% | 🟢 Faible |
| **config.sh** | ~330 | ❌ 0 | ~0% | 🟢 Faible |
| **git-mirror.sh** | 928 | ❌ 0 | ~0% | 🟢 Intégration |
| **TOTAL** | ~4198 | - | 2.69% | - |

## Stratégie de Maximisation

### Étape 1 : Tests Modules Critiques (git_ops, api, auth)
**Objectif**: 200-300 tests, couverture ~70% de ces modules

#### git_ops.sh (441 lignes)
- Test avec mocks git
- Tests clone, update, fetch
- Tests gestion erreurs et retry
- Tests submodules
- **Objectif**: 50+ tests

#### github_api.sh (481 lignes)  
- Test avec mocks curl
- Tests pagination, cache, rate limiting
- Tests gestion headers
- Tests codes HTTP
- **Objectif**: 80+ tests

#### auth.sh (366 lignes)
- Tests détection méthode auth
- Tests validation tokens
- Tests transformation URLs
- **Objectif**: 40+ tests

### Étape 2 : Tests Modules Métier (cache, filters, metrics)
**Objectif**: 150-200 tests, couverture ~60%

### Étape 3 : Tests Modules UI (interactive, state)
**Objectif**: 100-150 tests, couverture ~50%

### Étape 4 : Tests D'Intégration
**Objectif**: Tests end-to-end avec mocks complets

## Plan D'Action Immédiat

1. **Corriger validation_spec.sh** (1 fail, 13 warnings)
2. **Créer test_git_ops_complete_spec.sh** (50+ tests)
3. **Créer test_api_complete_spec.sh** (80+ tests)
4. **Créer test_auth_complete_spec.sh** (40+ tests)
5. **Enrichir tests existants** avec edge cases
6. **Ajouter tests d'intégration** entre modules

## Estimation

- Tests à créer: ~400-500 tests
- Temps estimé: 8-12 heures pour 90%+
- Priorité: Focus assertif sur modules critiques d'abord

## Mocks Nécessaires

- ✅ curl : Présent
- ✅ git : Présent
- ✅ jq : Présent
- ⏳ date : À créer
- ⏳ stat : À créer
- ⏳ mktemp : À créer
