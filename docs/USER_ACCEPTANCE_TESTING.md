# Plan de Recette Utilisateur - Git Mirror

**Date**: 2025-01-29  
**Version**: 2.0.0

## Objectif

Ce document définit le plan de recette utilisateur (UAT) pour valider que Git Mirror répond aux besoins des utilisateurs finaux.

## 1. Scénarios de Test Utilisateur

### Scénario 1 : Utilisateur Débutant

**Objectif**: Vérifier qu'un utilisateur novice peut utiliser Git Mirror facilement.

**Prérequis**:
- Git installé
- Compte GitHub (public)

**Étapes**:
1. ✅ Installer Git Mirror selon USER_GUIDE.md
2. ✅ Exécuter: `./git-mirror.sh users octocat`
3. ✅ Vérifier que les dépôts sont clonés
4. ✅ Consulter l'aide: `./git-mirror.sh --help`

**Critères de Succès**:
- [ ] Installation réussie sans erreur
- [ ] Exécution réussie sans configuration complexe
- [ ] Dépôts clonés correctement
- [ ] Aide claire et compréhensible

**Durée Estimée**: 15 minutes

---

### Scénario 2 : Utilisateur Intermédiaire - Synchronisation Régulière

**Objectif**: Vérifier le mode incrémental pour synchronisation régulière.

**Prérequis**:
- Git Mirror installé
- Token GitHub configuré
- Première synchronisation effectuée

**Étapes**:
1. ✅ Première exécution: `./git-mirror.sh --incremental users octocat`
2. ✅ Attendre modification d'un dépôt sur GitHub
3. ✅ Deuxième exécution: `./git-mirror.sh --incremental users octocat`
4. ✅ Vérifier que seul le dépôt modifié est mis à jour

**Critères de Succès**:
- [ ] Première exécution clone tous les dépôts
- [ ] Deuxième exécution ne traite que les modifiés
- [ ] Temps d'exécution réduit significativement
- [ ] Aucun dépôt non modifié n'est touché

**Durée Estimée**: 30 minutes

---

### Scénario 3 : Utilisateur Avancé - Mode Parallèle

**Objectif**: Vérifier le mode parallèle pour performance maximale.

**Prérequis**:
- Git Mirror installé
- GNU parallel installé
- Token GitHub avec quotas élevés

**Étapes**:
1. ✅ Exécuter sans parallèle: `./git-mirror.sh users microsoft --metrics`
2. ✅ Noter le temps d'exécution
3. ✅ Exécuter avec parallèle: `./git-mirror.sh --parallel --jobs 10 users microsoft --metrics`
4. ✅ Comparer les temps et métriques

**Critères de Succès**:
- [ ] Mode parallèle plus rapide (au moins 2x)
- [ ] Métriques disponibles et correctes
- [ ] Aucune erreur de concurrence
- [ ] Utilisation CPU/mémoire raisonnable

**Durée Estimée**: 20 minutes

---

### Scénario 4 : Administrateur - Backup Complet

**Objectif**: Vérifier le backup complet d'une organisation.

**Prérequis**:
- Git Mirror installé
- Accès à une organisation GitHub
- Espace disque suffisant

**Étapes**:
1. ✅ Exécuter: `./git-mirror.sh orgs myorg --dest ./backup --metrics --metrics-file report.json`
2. ✅ Vérifier tous les dépôts clonés
3. ✅ Consulter le rapport de métriques
4. ✅ Vérifier l'intégrité des dépôts

**Critères de Succès**:
- [ ] Tous les dépôts clonés
- [ ] Rapport de métriques généré
- [ ] Dépôts vérifiables (git status OK)
- [ ] Aucune corruption détectée

**Durée Estimée**: 1 heure (selon nombre de dépôts)

---

### Scénario 5 : Développeur - Filtrage Avancé

**Objectif**: Vérifier les fonctionnalités de filtrage.

**Prérequis**:
- Git Mirror installé
- Compte GitHub avec plusieurs dépôts

**Étapes**:
1. ✅ Exclure les forks: `./git-mirror.sh --exclude-forks users myuser`
2. ✅ Filtrer par pattern: `./git-mirror.sh --include "project-*" users myuser`
3. ✅ Combiner filtres: `./git-mirror.sh --exclude-forks --include "lib-*" users myuser`
4. ✅ Vérifier que seuls les dépôts correspondants sont clonés

**Critères de Succès**:
- [ ] Exclusion des forks fonctionne
- [ ] Patterns d'inclusion fonctionnent
- [ ] Combinaison de filtres fonctionne
- [ ] Résultats conformes aux attentes

**Durée Estimée**: 20 minutes

---

### Scénario 6 : CI/CD - Intégration Automatique

**Objectif**: Vérifier l'intégration dans un pipeline CI/CD.

**Prérequis**:
- Git Mirror installé
- Pipeline CI/CD (GitHub Actions, GitLab CI, etc.)
- Token GitHub configuré

**Étapes**:
1. ✅ Créer workflow CI/CD utilisant Git Mirror
2. ✅ Exécuter le pipeline
3. ✅ Vérifier les résultats
4. ✅ Vérifier les logs et métriques

**Critères de Succès**:
- [ ] Pipeline s'exécute sans erreur
- [ ] Git Mirror fonctionne en mode non-interactif
- [ ] Métriques disponibles
- [ ] Logs appropriés

**Durée Estimée**: 30 minutes

---

## 2. Tests de Compatibilité

### 2.1 Systèmes d'Exploitation

- [ ] Linux (Ubuntu 20.04+)
- [ ] Linux (Debian 11+)
- [ ] Linux (CentOS 8+)
- [ ] macOS (Big Sur+)
- [ ] macOS (Monterey+)
- [ ] Windows (WSL2)

### 2.2 Versions de Dépendances

- [ ] Git 2.25+
- [ ] Git 2.40+ (dernière)
- [ ] jq 1.6+
- [ ] jq 1.7+ (dernière)
- [ ] Bash 4.0+
- [ ] Bash 5.0+ (dernière)

### 2.3 Environnements

- [ ] Terminal interactif
- [ ] Terminal non-interactif
- [ ] SSH session
- [ ] CI/CD pipeline
- [ ] Docker container

## 3. Tests de Robustesse

### 3.1 Gestion d'Erreurs

- [ ] Réseau indisponible
- [ ] API GitHub indisponible
- [ ] Token invalide/expiré
- [ ] Espace disque insuffisant
- [ ] Permissions insuffisantes
- [ ] Dépôt corrompu
- [ ] Interruption (Ctrl+C)

### 3.2 Cas Limites

- [ ] Utilisateur sans dépôts
- [ ] Organisation avec 1000+ dépôts
- [ ] Dépôts avec noms spéciaux
- [ ] Dépôts très volumineux (>1GB)
- [ ] Dépôts avec beaucoup de branches

## 4. Critères d'Acceptation Globaux

### Fonctionnalité

- [ ] Tous les scénarios passent
- [ ] Aucune régression détectée
- [ ] Performance conforme aux attentes
- [ ] Compatibilité avec tous les environnements cibles

### Utilisabilité

- [ ] Documentation claire et complète
- [ ] Messages d'erreur informatifs
- [ ] Aide (`--help`) complète
- [ ] Exemples d'utilisation fonctionnels

### Qualité

- [ ] Aucun bug critique
- [ ] Bugs mineurs documentés et acceptables
- [ ] Performance acceptable
- [ ] Sécurité validée

## 5. Plan d'Exécution

### Phase 1 : Tests Internes (Semaine 1)

- Tests par l'équipe de développement
- Correction des bugs critiques
- Validation des scénarios de base

### Phase 2 : Tests Bêta (Semaine 2-3)

- Tests par utilisateurs bêta sélectionnés
- Collecte de feedback
- Améliorations basées sur feedback

### Phase 3 : Tests de Validation (Semaine 4)

- Tests finaux par utilisateurs finaux
- Validation des critères d'acceptation
- Préparation release

## 6. Collecte de Feedback

### Méthodes

1. **Questionnaires**
   - Facilité d'utilisation (1-5)
   - Satisfaction globale (1-5)
   - Fonctionnalités manquantes

2. **Interviews**
   - Utilisateurs avancés
   - Cas d'usage spécifiques
   - Problèmes rencontrés

3. **Métriques**
   - Taux de succès des exécutions
   - Temps moyen d'exécution
   - Erreurs les plus fréquentes

### Questions Clés

1. Le script est-il facile à utiliser ?
2. La documentation est-elle claire ?
3. Y a-t-il des fonctionnalités manquantes ?
4. Rencontrez-vous des problèmes ?
5. Recommanderiez-vous Git Mirror ?

## 7. Rapport de Recette

### Template

```markdown
# Rapport de Recette - Git Mirror v2.0.0

**Date**: [DATE]
**Testeur**: [NOM]
**Environnement**: [OS, Versions]

## Résultats

### Scénarios Testés
- [ ] Scénario 1: ✅/❌
- [ ] Scénario 2: ✅/❌
- ...

### Bugs Découverts
1. [Description] - Criticité: [Haute/Moyenne/Basse]

### Feedback
[Commentaires libres]

## Recommandation
- [ ] ✅ Accepté pour release
- [ ] ⚠️ Accepté avec réserves
- [ ] ❌ Non accepté
```

## 8. Checklist de Release

Avant de considérer la release comme prête :

- [ ] Tous les scénarios UAT passent
- [ ] Documentation complète et à jour
- [ ] Aucun bug critique ouvert
- [ ] Performance validée
- [ ] Sécurité validée
- [ ] Compatibilité vérifiée
- [ ] Feedback utilisateurs positif
- [ ] CHANGELOG à jour

---

**Prochaine Révision**: Après chaque release majeure  
**Responsable**: Product Owner / Équipe de développement
