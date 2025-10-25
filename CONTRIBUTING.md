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
   ./install.sh --deps
   ```

2. Exécutez les tests pour vérifier que tout fonctionne :
   ```bash
   make test
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

## Checklist

- [ ] Mon code respecte les standards du projet
- [ ] J'ai effectué une auto-révision de mon code
- [ ] J'ai commenté les parties complexes de mon code
- [ ] J'ai mis à jour la documentation
- [ ] Mes changements ne génèrent pas de nouveaux warnings
- [ ] J'ai ajouté des tests qui prouvent que ma correction est efficace
- [ ] Les tests passent localement
- [ ] J'ai mis à jour le CHANGELOG si nécessaire
```

## Rapport de Bugs

### Template de Bug Report

```markdown
## Description du Bug

Description claire et concise du bug.

## Étapes pour Reproduire

1. Aller à '...'
2. Cliquer sur '...'
3. Faire défiler jusqu'à '...'
4. Voir l'erreur

## Comportement Attendu

Description claire et concise du comportement attendu.

## Comportement Actuel

Description claire et concise du comportement actuel.

## Environnement

- OS: [ex: Ubuntu 20.04]
- Version de Bash: [ex: 5.0.17]
- Version de Git: [ex: 2.25.1]
- Version de jq: [ex: 1.6]
- Version de Git Mirror: [ex: 2.0.0]

## Logs

```
Coller les logs d'erreur ici
```

## Informations Supplémentaires

Toute autre information pertinente.
```

## Demande de Fonctionnalités

### Template de Feature Request

```markdown
## Description de la Fonctionnalité

Description claire et concise de la fonctionnalité souhaitée.

## Problème Résolu

Description du problème que cette fonctionnalité résoudrait.

## Solution Proposée

Description claire et concise de la solution proposée.

## Alternatives Considérées

Description des solutions alternatives considérées.

## Contexte Supplémentaire

Toute autre information pertinente.
```

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
