# Guide de Contribution - Git Mirror

Merci de votre intérêt à contribuer à Git Mirror ! Ce guide vous aidera à comprendre comment contribuer efficacement au projet.

## Table des Matières

- [Code de Conduite](#code-de-conduite)
- [Comment Contribuer](#comment-contribuer)
- [Standards de Code](#standards-de-code)
- [Processus de Tests](#processus-de-tests)
- [Processus de Pull Request](#processus-de-pull-request)
- [Rapport de Bugs](#rapport-de-bugs)
- [Demande de Fonctionnalités](#demande-de-fonctionnalités)

## Code de Conduite

Ce projet adhère à un code de conduite basé sur le respect mutuel et la collaboration constructive. Nous nous attendons à ce que tous les contributeurs :

- Soient respectueux et inclusifs
- Communiquent de manière constructive
- Respectent les opinions et les points de vue différents
- Collaborent de manière positive

## Comment Contribuer

### 1. Fork du Projet

1. Fork le projet sur GitHub
2. Clone votre fork localement :
   ```bash
   git clone https://github.com/votre-username/git-mirror.git
   cd git-mirror
   ```

### 2. Configuration de l'Environnement

1. Installez les dépendances :

   ```bash
   # Option 1 : Utiliser le script d'installation
   ./install.sh --deps
   
   # Option 2 : Utiliser le Makefile
   make install-deps
   
   # Option 3 : Installation manuelle
   sudo apt-get update && sudo apt-get install -y jq parallel git curl bash
   ```

2. Exécutez les tests pour vérifier que tout fonctionne :

   ```bash
   # Tests complets
   make test
   
   # Ou individuellement
   make test-shellcheck
   make test-bats
   make test-integration
   ```

### 3. Création d'une Branche

1. Créez une branche pour votre contribution :
   ```bash
   git checkout -b feature/nom-de-votre-fonctionnalite
   ```

2. Ou pour un correctif :
   ```bash
   git checkout -b fix/description-du-bug
   ```

## Standards de Code

### Bash

- Utilisez `set -euo pipefail` au début de chaque script
- Utilisez des noms de variables en MAJUSCULES pour les constantes
- Utilisez des noms de fonctions en snake_case
- Ajoutez des commentaires pour expliquer la logique complexe
- Utilisez `readonly` pour les variables qui ne changent pas

### Structure des Fichiers

- Placez les modules dans `lib/`
- Placez la configuration dans `config/`
- Placez les tests dans `tests/`
- Placez la documentation dans `docs/`

### Nommage

- Utilisez des noms descriptifs pour les variables et fonctions
- Utilisez des préfixes pour les fonctions des modules (ex: `auth_`, `api_`, `state_`)
- Utilisez des suffixes pour les fichiers de test (ex: `test_*.bats`)

## Processus de Tests

### Tests Unitaires

Exécutez les tests unitaires avec Bats :

```bash
bats tests/unit/
```

### Tests d'Intégration

Exécutez les tests d'intégration :

```bash
bash tests/integration/test_integration.sh
```

### Tests de Charge

Exécutez les tests de charge :

```bash
bash tests/load/test_load.sh --dry-run --repos 50 --parallel 5
```

### Validation du Code

Exécutez ShellCheck pour valider le code :

```bash
shellcheck git-mirror.sh lib/*/*.sh config/*.sh
```

### Tests Complets

Exécutez tous les tests :

```bash
make test
```

## Processus de Pull Request

### 1. Préparation

1. Assurez-vous que votre code respecte les standards
2. Exécutez tous les tests et vérifiez qu'ils passent
3. Mettez à jour la documentation si nécessaire
4. Commitez vos changements avec des messages clairs

### 2. Création de la Pull Request

1. Poussez votre branche vers votre fork
2. Créez une Pull Request sur GitHub
3. Remplissez le template de Pull Request
4. Assignez des reviewers si nécessaire

### 3. Template de Pull Request

```markdown
## Description

Brève description des changements apportés.

## Type de Changement

- [ ] Correction de bug
- [ ] Nouvelle fonctionnalité
- [ ] Changement cassant
- [ ] Documentation
- [ ] Tests
- [ ] Refactoring

## Tests

- [ ] Tests unitaires passés
- [ ] Tests d'intégration passés
- [ ] Tests de charge passés
- [ ] ShellCheck sans erreurs

Le template complet de Pull Request est disponible dans `.github/pull_request_template.md`. Veuillez l'utiliser lors de la création d'une PR.

## Processus d'Audit Ligne par Ligne

Conformément aux règles strictes du projet, tout travail sur le code nécessite un audit complet :

### Règles Absolues pour Tout Travail sur le Code

1. **UN SEUL MODULE À LA FOIS** : Ne jamais faire de modifications "batch"
2. **ANALYSE COMPLÈTE LIGNE PAR LIGNE** : 100% des lignes lues et comprises
3. **AUDIT OBLIGATOIRE AVANT TOUTE MODIFICATION** :
   - **Audit fonctionnel** : Fonctions, paramètres, dépendances, variables globales
   - **Analyse qualité** : Complexité cyclomatique, style, gestion erreurs, performance
   - **Review architecture** : Design Patterns, abstraction, standards projet
4. **DOCUMENTATION EXHAUSTIVE** : Rapport détaillé avec recommandations
5. **VALIDATION EXPRESSE REQUISE** : Attendre approbation avant module suivant
6. **AUCUNE DEADLINE** : La qualité prime TOUJOURS sur la vitesse
7. **ZÉRO TOLÉRANCE** : Pour approche rapide/superficielle

### Processus pour Chaque Module

1. **Lecture complète** : 100% des lignes du module
2. **Audit statique** : ShellCheck ligne par ligne
3. **Review architecture** : Design Patterns appliqués
4. **Modifications** : UNE modification à la fois, test après chaque modification
5. **Documentation** : Justification de CHAQUE changement
6. **Validation finale** : 0 erreur, tests de régression, approbation

### Workflow de Développement avec Branches

```
main
├── feature/nom-feature
│   └── work/travail-ongoing
├── fix/nom-fix
│   └── work/travail-ongoing
└── refactor/nom-refactor
    └── work/travail-ongoing
```

**Convention de nommage** :
- `feature/` : Nouvelles fonctionnalités
- `fix/` : Corrections de bugs
- `refactor/` : Refactorings
- `docs/` : Documentation uniquement
- `test/` : Ajout de tests uniquement

**Branches de travail** : Utiliser `work/` pour les travaux en cours sur une branche principale

## Rapport de Bugs

Les templates de rapport Lambda et de demande de fonctionnalité sont disponibles dans `.github/ISSUE_TEMPLATE/`. Veuillez utiliser ces templates lors de la création d'une nouvelle issue.

- [Bug Report Template](.github/ISSUE_TEMPLATE/bug_report.md)
- [Feature Request Template](.github/ISSUE_TEMPLATE/feature_request.md)

Pour créer une nouvelle issue :
1. Allez sur la page des issues du projet
2. Cliquez sur "New Issue"
3. Sélectionnez le template approprié
4. Remplissez les informations demandées

## Processus de Review

### Pour les Reviewers

1. Vérifiez que le code respecte les standards
2. Vérifiez que les tests passent
3. Vérifiez que la documentation est mise à jour
4. Testez les changements localement si nécessaire
5. Fournissez des commentaires constructifs

### Pour les Contributeurs

1. Répondez aux commentaires des reviewers
2. Effectuez les changements demandés
3. Mettez à jour la Pull Request
4. Communiquez clairement sur les changements effectués

## Questions et Support

Si vous avez des questions ou besoin d'aide :

1. Consultez la documentation dans `docs/`
2. Recherchez dans les issues existantes
3. Créez une nouvelle issue si nécessaire
4. Rejoignez la discussion dans les discussions GitHub

## Reconnaissance

Merci à tous les contributeurs qui rendent ce projet possible !

## Licence

En contribuant à ce projet, vous acceptez que vos contributions soient sous la même licence que le projet.
