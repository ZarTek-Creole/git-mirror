# Architecture Decision Records (ADR)

Ce document enregistre les décisions architecturales importantes prises dans le projet Git Mirror.

## Format

Chaque ADR suit le format :
- **Contexte** : La situation qui nécessite une décision
- **Décision** : La décision prise
- **Conséquences** : Les impacts positifs et négatifs

---

## ADR-001 : Architecture Modulaire

**Date**: 2025-01-29  
**Statut**: Accepté  
**Décideurs**: Équipe de développement

### Contexte

Le script initial était monolithique, difficile à maintenir et tester. Une refactorisation était nécessaire.

### Décision

Adopter une architecture modulaire avec séparation claire des responsabilités :
- `lib/` : Modules fonctionnels
- `config/` : Configuration centralisée
- `tests/` : Tests organisés par type
- `scripts/` : Scripts utilitaires

### Conséquences

**Positifs**:
- ✅ Facilité de maintenance
- ✅ Tests unitaires isolés
- ✅ Réutilisabilité des modules
- ✅ Séparation des préoccupations

**Négatifs**:
- ⚠️ Plus de fichiers à gérer
- ⚠️ Nécessite une documentation claire

---

## ADR-002 : Framework de Tests ShellSpec

**Date**: 2025-01-29  
**Statut**: Accepté  
**Décideurs**: Équipe de développement

### Contexte

Besoin d'un framework de tests BDD pour Bash avec couverture de code.

### Décision

Utiliser ShellSpec comme framework de tests principal :
- Syntaxe BDD (`Describe`, `It`, `When call`)
- Support de la couverture avec kcov
- Tests lisibles et maintenables

### Conséquences

**Positifs**:
- ✅ Tests BDD expressifs
- ✅ Intégration avec outils de couverture
- ✅ Documentation vivante

**Négatifs**:
- ⚠️ Courbe d'apprentissage
- ⚠️ Dépendance externe supplémentaire

---

## ADR-003 : Cache API avec TTL

**Date**: 2025-01-29  
**Statut**: Accepté  
**Décideurs**: Équipe de développement

### Contexte

Réduire les appels API GitHub pour éviter les limites de taux et améliorer les performances.

### Décision

Implémenter un système de cache avec TTL :
- Cache par défaut : 1 heure
- TTL configurable
- Nettoyage automatique des entrées expirées
- Cache désactivable via `--no-cache`

### Conséquences

**Positifs**:
- ✅ Réduction des appels API (90%+)
- ✅ Amélioration des performances
- ✅ Respect des limites de taux

**Négatifs**:
- ⚠️ Gestion de la cohérence des données
- ⚠️ Consommation d'espace disque

---

## ADR-004 : Process Substitution pour Fusion JSON

**Date**: 2025-01-29  
**Statut**: Accepté  
**Décideurs**: Équipe de développement

### Contexte

Optimisation de `api_fetch_all_repos()` qui utilisait 3 fichiers temporaires par itération.

### Décision

Utiliser la process substitution Bash `<()` au lieu de fichiers temporaires :
```bash
all_repos=$(jq -s '.[0] + .[1]' <(echo "$all_repos") <(echo "$response"))
```

### Conséquences

**Positifs**:
- ✅ Réduction de 30% des I/O disque
- ✅ Code plus simple
- ✅ Meilleures performances

**Négatifs**:
- ⚠️ Nécessite Bash 4.0+
- ⚠️ Moins de débogage (pas de fichiers intermédiaires)

---

## ADR-005 : Filtrage jq Direct au lieu de Boucles

**Date**: 2025-01-29  
**Statut**: Accepté  
**Décideurs**: Équipe de développement

### Contexte

Plusieurs fonctions utilisaient des boucles Bash avec appels jq répétés (O(n²)).

### Décision

Remplacer les boucles par des opérations jq directes :
```bash
# Avant (O(n²))
while read -r line; do
    repo=$(echo "$json" | jq "select(.name == \"$line\")")
done

# Après (O(n))
filtered=$(echo "$json" | jq --argjson names "$names_list" '[.[] | select(.name as $n | $names | index($n) != null)]')
```

### Conséquences

**Positifs**:
- ✅ Performance améliorée de 80%
- ✅ Code plus lisible
- ✅ Moins d'appels système

**Négatifs**:
- ⚠️ Requiert jq avancé
- ⚠️ Moins de contrôle pas-à-pas

---

## ADR-006 : Variables Readonly pour Sécurité

**Date**: 2025-01-29  
**Statut**: Accepté  
**Décideurs**: Équipe de développement

### Contexte

Variables de configuration modifiables accidentellement, risques de sécurité.

### Décision

Déclarer toutes les constantes de configuration comme `readonly` :
```bash
readonly DEFAULT_CACHE_TTL=3600
readonly MAX_GIT_RETRIES=3
readonly API_BASE_URL="https://api.github.com"
```

### Conséquences

**Positifs**:
- ✅ Sécurité renforcée
- ✅ Prévention des erreurs
- ✅ Code plus robuste

**Négatifs**:
- ⚠️ Moins de flexibilité (nécessite redéclaration pour tests)

---

## ADR-007 : Système de Logging Modulaire

**Date**: 2025-01-29  
**Statut**: Accepté  
**Décideurs**: Équipe de développement

### Contexte

Besoin d'un système de logging cohérent avec niveaux et couleurs.

### Décision

Créer un module de logging centralisé (`lib/logging/logger.sh`) :
- Niveaux : DEBUG, INFO, SUCCESS, WARNING, ERROR, FATAL
- Couleurs pour chaque niveau
- Redirection stderr pour logs
- Configuration via `VERBOSE_LEVEL`

### Conséquences

**Positifs**:
- ✅ Logging cohérent
- ✅ Contrôle granulaire
- ✅ Facilité de débogage

**Négatifs**:
- ⚠️ Dépendance à toutes les fonctions
- ⚠️ Initialisation nécessaire

---

## ADR-008 : Mode Parallèle avec Auto-Tuning

**Date**: 2025-01-29  
**Statut**: Accepté  
**Décideurs**: Équipe de développement

### Contexte

Besoin d'optimiser automatiquement le nombre de jobs parallèles.

### Décision

Implémenter un système d'auto-tuning basé sur :
- Nombre de CPU disponibles
- Mémoire disponible
- Connectivité réseau
- Quotas API

Via le module `parallel_optimized.sh`.

### Conséquences

**Positifs**:
- ✅ Performance optimale automatique
- ✅ Adaptation dynamique
- ✅ Moins de configuration manuelle

**Négatifs**:
- ⚠️ Complexité supplémentaire
- ⚠️ Dépendance à GNU parallel

---

## ADR-009 : Support de Plusieurs Méthodes d'Authentification

**Date**: 2025-01-29  
**Statut**: Accepté  
**Décideurs**: Équipe de développement

### Contexte

Flexibilité nécessaire pour différents environnements (CI/CD, local, serveur).

### Décision

Implémenter Pattern Strategy pour l'authentification :
- Token GitHub (recommandé)
- Clé SSH
- Public (sans authentification)
- GitHub CLI

Détection automatique de la méthode disponible.

### Conséquences

**Positifs**:
- ✅ Flexibilité maximale
- ✅ Compatibilité multiple environnements
- ✅ Dégradation gracieuse

**Négatifs**:
- ⚠️ Complexité de gestion
- ⚠️ Plus de code à maintenir

---

## ADR-010 : Tests de 100% Couverture

**Date**: 2025-01-29  
**Statut**: Accepté  
**Décideurs**: Équipe de développement

### Contexte

Objectif de qualité et maintenabilité à long terme.

### Décision

Atteindre et maintenir 100% de couverture de tests pour toutes les fonctions publiques.

### Conséquences

**Positifs**:
- ✅ Confiance dans le code
- ✅ Documentation vivante
- ✅ Détection précoce des régressions

**Négatifs**:
- ⚠️ Temps de développement initial élevé
- ⚠️ Maintenance des tests nécessaire

---

## ADR-011 : Documentation Utilisateur Complète

**Date**: 2025-01-29  
**Statut**: Accepté  
**Décideurs**: Équipe de développement

### Contexte

Faciliter l'adoption et réduire la courbe d'apprentissage.

### Décision

Créer une documentation exhaustive :
- Guide utilisateur complet
- Référence API
- Exemples d'utilisation
- Dépannage

### Conséquences

**Positifs**:
- ✅ Adoption facilitée
- ✅ Moins de questions
- ✅ Projet professionnel

**Négatifs**:
- ⚠️ Maintenance nécessaire
- ⚠️ Synchronisation avec code

---

## ADR-012 : Scripts d'Analyse Automatisés

**Date**: 2025-01-29  
**Statut**: Accepté  
**Décideurs**: Équipe de développement

### Contexte

Besoin d'outils pour maintenir la qualité du code.

### Décision

Créer des scripts d'analyse :
- `analyze-coverage.sh` : Couverture de code
- `analyze-complexity.sh` : Complexité cyclomatique
- `improve-code-quality.sh` : Meilleures pratiques
- `comprehensive-check.sh` : Vérification complète

### Conséquences

**Positifs**:
- ✅ Qualité maintenue automatiquement
- ✅ Détection précoce des problèmes
- ✅ Métriques objectives

**Négatifs**:
- ⚠️ Maintenance des scripts
- ⚠️ Temps d'exécution

---

## Références

- [ADR Template](https://adr.github.io/)
- [Documentation du projet](./README.md)
- [Architecture](./ARCHITECTURE.md)
