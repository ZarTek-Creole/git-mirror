# Architecture Git Mirror

## 📁 Structure du Projet

```
git-mirror/
├── git-mirror.sh              # Script principal (modulaire)
├── archive/
│   └── git-mirror-legacy.sh   # Ancien script monolithique (backup)
├── lib/                        # Modules fonctionnels
│   ├── logging/
│   │   └── logger.sh          # Module de logging
│   ├── auth/
│   │   └── auth.sh            # Module d'authentification
│   ├── api/
│   │   └── github_api.sh     # Module API GitHub
│   ├── validation/
│   │   └── validation.sh      # Module de validation
│   ├── git/
│   │   └── git_ops.sh        # Module opérations Git
│   └── cache/
│       └── cache.sh          # Module de cache
├── config/
│   └── config.sh             # Configuration centralisée
├── tests/
│   └── unit/
│       └── test_modules_simple.sh  # Tests unitaires
├── .github/
│   └── workflows/
│       └── test-architecture.yml    # GitHub Actions
└── README.md                 # Documentation
```

## 🔄 Évolution du Script

### Phase 1 : Script Monolithique
- **Fichier** : `archive/git-mirror-legacy.sh` (1801 lignes)
- **Caractéristiques** : Tout dans un seul fichier
- **Avantages** : Simple à distribuer
- **Inconvénients** : Difficile à maintenir, tester et étendre

### Phase 2.1 : Architecture Modulaire ✅
- **Fichier principal** : `git-mirror.sh` (536 lignes)
- **Modules** : 7 modules spécialisés dans `lib/`
- **Configuration** : Centralisée dans `config/`
- **Tests** : Suite de tests complète
- **Avantages** : Maintenable, testable, extensible

## 🎯 Pourquoi Cette Architecture ?

### ✅ Avantages de l'Architecture Modulaire
1. **Séparation des responsabilités** - Chaque module a une fonction spécifique
2. **Réutilisabilité** - Les modules peuvent être utilisés indépendamment
3. **Maintenabilité** - Code organisé et facile à maintenir
4. **Testabilité** - Chaque module peut être testé séparément
5. **Extensibilité** - Facile d'ajouter de nouveaux modules
6. **Design Patterns** - Architecture basée sur les patterns éprouvés

### 🏗️ Design Patterns Utilisés
- **Facade** : Interface simplifiée pour les modules complexes
- **Strategy** : Algorithmes interchangeables (auth, validation)
- **Observer** : Notifications et événements
- **Singleton** : Configuration globale unique
- **Builder** : Construction d'objets complexes
- **Command** : Encapsulation des opérations Git
- **Chain of Responsibility** : Validation en chaîne

## 🚀 Utilisation

```bash
# Utilisation normale
./git-mirror.sh users username

# Avec options avancées
./git-mirror.sh -d /path/to/repos -b main --dry-run users username

# Mode verbeux pour debug
./git-mirror.sh -vv users username
```

## 📊 Métriques

| Aspect | Monolithique | Modulaire |
|--------|-------------|-----------|
| Lignes de code | 1801 | 536 (principal) + modules |
| Modules | 1 | 7 |
| Testabilité | Difficile | Facile |
| Maintenabilité | Complexe | Simple |
| Extensibilité | Limitée | Excellente |
| Réutilisabilité | Faible | Élevée |

---
**Status** : ✅ Architecture modulaire opérationnelle  
**Version** : 2.1  
**Prochaine étape** : Phase 2.2 - Authentification GitHub
