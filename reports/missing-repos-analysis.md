# Analyse - Dépôts Manquants

**Date** : 2025-10-27  
**Problème** : Dépôts manquants dans les répertoires de test

## 🔍 Observations

### Résultats Attendus
- **zartek-all** : 249 dépôts
- **zartek-public** : 154 dépôts  
- **zartek-private** : 95 dépôts

### Résultats Observés (après timeout 30s)
- **zartek-all** : 10 dépôts seulement
- **zartek-public** : 9 dépôts seulement
- **zartek-private** : 10 dépôts seulement

## 📊 Analyse

### Cause Principale : Timeout
Les tests ont été interrompus par un timeout de 30 secondes alors qu'ils nécessitent beaucoup plus de temps pour cloner tous les dépôts.

### Problème Identifié : Incohérence du cache
```
[DEBUG] Nombre total de dépôts calculé: 100
[INFO] Nombre total de dépôts à traiter: 100
[DEBUG] Nombre réel de dépôts récupérés: 249
```

Le cache retourne 100 dépôts (ancien total) mais l'API retourne 249 dépôts.

## 🔧 Solutions

### 1. Invalider le cache du comptage total
Le cache pour `api_get_total_repos` doit inclure le paramètre `REPO_TYPE` dans sa clé de cache, sinon il retourne toujours l'ancien total.

### 2. Utiliser le nombre réel récupéré
Le script met déjà à jour `total_repos` après la récupération (lignes 633-638 de git-mirror.sh), mais le message initial affiche l'ancien cache.

### 3. Correction à appliquer
Modifier `api_get_total_repos` pour inclure `REPO_TYPE` dans la clé de cache.

## 📝 Action Immédiate

Le test en arrière-plan va confirmer que tous les dépôts sont bien récupérés quand on laisse le temps au script de s'exécuter complètement.

**Solution** : Vérifier que tous les 249 dépôts sont présents dans `test-all` une fois le test terminé.

