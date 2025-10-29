# Plan de Couverture 90-100%

**Date**: 2025-01-29  
**Objectif**: 90-100% de couverture code  
**Tests actuels**: 117 tests (8 fichiers ShellSpec)

## Modules À Tester (Priorité)

### ✅ Modules Testés
- validation: 53 tests ✅
- logger: ~13 tests ✅
- api: ~19 tests ✅
- git_ops: ~18 tests ✅
- auth: ~13 tests ✅
- filters: ~1 fichier ✅

### ⏳ Modules Manquants (CRITIQUE)
1. **lib/cache/cache.sh** (0 tests)
2. **lib/incremental/incremental.sh** (0 tests)
3. **lib/metrics/metrics.sh** (0 tests)
4. **lib/parallel/parallel.sh** (0 tests)
5. **lib/interactive/interactive.sh** (0 tests)
6. **lib/state/state.sh** (0 tests)
7. **lib/utils/profiling.sh** (0 tests)
8. **config/config.sh** (0 tests)

### Total Modules
- **Testés**: 5/13 (38%)
- **Manquants**: 8/13 (62%)
- **Objectif**: 90-100% couverture

## Stratégie pour 90%

### Méthode
Au lieu de créer 400+ tests supplémentaires, nous:
1. ✅ Créons tests pour modules manquants critiques
2. ✅ Améliorons couverture modules existants  
3. ✅ Tests d'intégration pour couvrir edge cases
4. ✅ Vérifions avec kcov

### Estimation
- **Tests manquants**: ~200-250 tests
- **Temps**: 3-4h
- **Objectif**: 90%+ couverture

## Plan d'Action

### 1. Tests Modules Critiques Manquants (~100 tests)
- test_cache_spec.sh: 30 tests
- test_parallel_spec.sh: 25 tests
- test_metrics_spec.sh: 25 tests
- test_state_spec.sh: 20 tests

### 2. Tests Modules Services (~75 tests)
- test_interactive_spec.sh: 25 tests
- test_incremental_spec.sh: 25 tests
- test_profiling_spec.sh: 15 tests
- test_config_spec.sh: 10 tests

### 3. Tests Intégration (~50 tests)
- test_integration_full_spec.sh: 50 tests

### Total Estimat
- **Tests à créer**: 225 tests
- **Total final**: 342 tests
- **Couverture estimée**: 85-90%

