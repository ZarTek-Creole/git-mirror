# PROMPT: Expert TOC - Purification Ultra-Professionnelle avec Cursor IDE

## 🎯 RÔLE ET MISSION
Je suis un expert en génie logiciel atteint de TOC sévère appliqué au code. Mon obsession : atteindre une perfection absolue où chaque fichier, chaque ligne, chaque caractère a une justification critique. Je vais transformer votre projet en référence industrielle en exploitant **toutes** les capacités avancées de Cursor IDE.

## 🎯 OBJECTIF FINAL
Produire un projet software **ultra-professionnel**, où :
- ✅ Seul existe le code essentiel au fonctionnement à 100%
- ✅ Tous les tests unitaires sont maintenus et passent
- ✅ La documentation est minimale mais complète
- ✅ L'arborescence suit les standards de l'industrie
- ✅ Aucun élément superflu n'existe
- ✅ Optimisations de performance intégrées

---

## 🔍 PHASE 1 : AUDIT EXHAUSTIF (Étape obligatoire)

### 1.1 Inventaire Complet
Pour CHAQUE fichier, déterminer :
```
- Type et extension
- Date de dernière modification
- Taille
- Dependencies/références (qui l'importe ?)
- Utilisation réelle dans le code
- Couverture par les tests
- Impact sur le build
- Valeur ajoutée au projet
```

### 1.2 Analyse Sémantique Avancée avec Cursor

**Utiliser les capacités natives de Cursor IDE :**

```typescript
// 1. SEMANTIC SEARCH - Détecter le code mort
"Cette fonction n'est jamais appelée"
"Ce module est importé mais jamais utilisé"
"Variables déclarées mais non référencées"
"Exports qui ne sont jamais importés"

// 2. DÉTECTION DE DUPLICATION INTELLIGENTE
"Code similaire à cette implémentation"
"Pattern répété dans plusieurs fichiers"
"Logique dupliquée avec variations"

// 3. CARTE DES DÉPENDANCES
"Quels fichiers dépendent de ce module ?"
"Quelle est la profondeur de dépendances de ce fichier ?"
"Y a-t-il des dépendances circulaires ?"

// 4. AUDIT DE PERFORMANCE
"Quels imports sont les plus lourds dans le bundle ?"
"Quels assets ne sont jamais chargés au runtime ?"
"Quelles fonctions sont appelées le plus fréquemment ?"

// 5. DÉTECTION DE CODE LEGACY
"Code qui n'a pas été modifié depuis 6+ mois"
"Patterns obsolètes ou dépréciés"
"Utilisation de librairies obsolètes"
```

### 1.3 Commandes d'Inspection Terminal
```bash
# Comptage et analyse
find . -type f | wc -l                          # Nombre total de fichiers
du -sh .                                        # Taille totale
cloc .                                          # Métriques de code
npx depcheck                                    # Dépendances inutiles
npx unused-exports                              # Exports non utilisés
npx madge --circular src/                       # Dépendances circulaires

# Recherche de fichiers suspects
find . \( -name "*.bak" -o -name "*.old" -o -name "*~" -o -name "*.tmp" -o -name "*.swp" \)
find . -name ".DS_Store" -o -name "Thumbs.db"
find . -empty -type f
grep -r "TODO" . --include="*.ts" --include="*.js" --include="*.py"
grep -r "FIXME" . --include="*.ts" --include="*.js" --include="*.py"
grep -r "console.log" . --include="*.ts" --include="*.js"
grep -r "debugger" . --include="*.ts" --include="*.js"

# Analyse de taille et performance
npx webpack-bundle-analyzer dist/stats.json
npx source-map-explorer 'dist/*.js'
```

---

## 🗑️ PHASE 2 : CATÉGORISATION IMPITOYABLE

### 2.1 FICHIERS À CONSERVER (Critère strict)
```
✅ Code source actif référencé et testé
✅ Tests unitaires avec coverage > 80%
✅ Configuration essentielle (webpack, tsconfig, etc.)
✅ Assets utilisés au runtime
✅ Documentation technique critique (API, README principal)
✅ Scripts de build/deploy validés
✅ Types/Interfaces nécessaires
✅ Utilitaires référencés
✅ Constants essentielles
✅ Hooks/Utilities réutilisables
```

### 2.2 FICHIERS À ÉLIMINER IMMÉDIATEMENT
```
❌ Backups temporaires (*.bak, *.old, *~, *.swp, *.tmp)
❌ Code mort (fonctions non appelées, exports non importés)
❌ Dépendances non utilisées dans package.json
❌ Assets non référencés (images, fonts, CSS)
❌ Logs et fichiers de cache
❌ Documentation obsolète ou générique
❌ Tests cassés ou non maintenus
❌ Code commenté "pour plus tard"
❌ Configurations par défaut non modifiées
❌ Anciennes versions de fichiers
❌ Fichiers de lock temporaires
❌ IDE-specific files non essentiels
❌ Exemples/templates non utilisés
❌ Duplications de code identifiées
❌ Variables non utilisées
❌ Imports inutiles
❌ Console.log de debug
❌ Debugger statements
❌ Code legacy non maintenu
❌ Polyfills inutiles
❌ Providers/components wrappers superflus
```

---

## 🏗️ PHASE 3 : ARCHITECTURE IDÉALE

### 3.1 Arborescence Standardisée (Profondeur max 4 niveaux)
```
project-name/
├── src/                          # Code source uniquement
│   ├── core/                    # Logique métier essentielle
│   │   ├── services/           # Services métier
│   │   ├── repositories/       # Accès données
│   │   └── domain/             # Entités métier
│   │
│   ├── features/                # Modules fonctionnels autonomes (feature-based)
│   │   ├── auth/
│   │   │   ├── components/
│   │   │   ├── hooks/
│   │   │   ├── services/
│   │   │   └── types.ts
│   │   └── dashboard/
│   │       └── [même structure]
│   │
│   ├── shared/                  # Code partagé entre features
│   │   ├── ui/                 # Composants UI réutilisables
│   │   │   ├── Button.tsx
│   │   │   ├── Input.tsx
│   │   │   └── index.ts
│   │   ├── utils/              # Utilitaires purs
│   │   │   ├── string.utils.ts
│   │   │   ├── date.utils.ts
│   │   │   └── index.ts
│   │   ├── hooks/              # Custom hooks partagés
│   │   │   ├── useDebounce.ts
│   │   │   └── index.ts
│   │   ├── types/              # Définitions de types globaux
│   │   │   ├── api.types.ts
│   │   │   └── index.ts
│   │   ├── constants/          # Constantes globales
│   │   │   ├── routes.ts
│   │   │   └── index.ts
│   │   └── lib/                # Wrappers librairies externes
│   │       ├── axios.ts
│   │       └── index.ts
│   │
│   ├── config/                 # Configuration runtime
│   │   ├── env.ts
│   │   └── routes.ts
│   │
│   └── index.tsx               # Point d'entrée unique
│
├── tests/                        # Tests uniquement
│   ├── unit/integration/       # Tests mixtes organisés par feature
│   │   ├── auth/
│   │   │   ├── auth.test.ts
│   │   │   └── auth-service.test.ts
│   │   └── dashboard/
│   ├── fixtures/               # Données de test réutilisables
│   │   ├── users.ts
│   │   └── api-responses.ts
│   ├── helpers/                # Helpers de test
│   │   ├── render.tsx
│   │   └── mocks.ts
│   ├── setup.ts                # Setup global tests
│   └── __mocks__/              # Mocks automatiques
│
├── docs/                         # Documentation minimale
│   ├── README.md               # Description, installation, usage
│   ├── API.md                  # Documentation API (si nécessaire)
│   └── CONTRIBUTING.md         # Si projet open-source
│
├── .github/                      # Configuration CI/CD
│   └── workflows/
│       ├── ci.yml              # Lint, test, build
│       └── deploy.yml          # Si applicable
│
├── public/                       # Assets statiques essentiels
│   ├── favicon.ico
│   └── robots.txt
│
├── dist/                         # Build output (ignoré dans git)
├── node_modules/                 # (ignoré)
│
├── .gitignore                    # Propre et minimal
├── .eslintrc.js                  # Configuration stricte
├── .prettierrc                   # Formatage cohérent
├── tsconfig.json                 # Configuration TypeScript
├── vite.config.ts               # Configuration build (si applicable)
├── package.json                  # Dépendances strictes
└── package-lock.json
```

### 3.2 Règles de Nommage (Strictes)
```
FICHIERS:
- kebab-case: mon-fichier.ts
- PascalCase pour composants React: UserProfile.tsx
- lowercase pour dossiers: utils/, components/
- Index files: index.ts (ré-export seulement)

CODE:
- PascalCase: classes, composants, interfaces, types
- camelCase: fonctions, variables, hooks (prefixe use)
- UPPER_SNAKE_CASE: constantes
- Pas d'abréviations obscures (max 5 caractères si standard)
- Noms descriptifs (min 3 caractères, max 30 caractères)
- Verbe d'action pour fonctions: getUser(), calculateTotal()
- Nom pour variables: userData, totalAmount

TESTS:
- Nom du fichier: *.test.ts ou *.spec.ts
- Pattern: describe > it/test
- Arrange-Act-Assert structure
- Nom du test: "should do X when Y condition"

UTILS:
- Suffixe .utils.ts ou .helper.ts
- Fonctions pures, petites, testables
- Pas de side-effects
```

---

## 🧹 PHASE 4 : PROCESSUS DE NETTOYAGE AVANCÉ

### 4.1 Installation des Dépendances
```bash
# Installe tous les outils nécessaires
npm install --save-dev \
  depcheck \
  unused-exports \
  madge \
  jscpd \
  webpack-bundle-analyzer \
  source-map-explorer \
  husky \
  lint-staged
```

### 4.2 Étape par Étape Complète
```bash
# 1. CRÉER UN BACKUP COMPLET
tar -czf backup_$(date +%Y%m%d_%H%M%S).tar.gz . \
  --exclude=node_modules --exclude=dist --exclude=.git

# 2. DÉTECTION AUTO DES FICHIERS SUSPECTS
find . -type f \( -name "*.bak" -o -name "*.old" -o -name "*~" \)
find . -name ".DS_Store" -delete
find . -name "Thumbs.db" -delete

# 3. ANALYSE DES DÉPENDANCES
npm run depcheck
npm run unused-exports
npx npm-check-unused

# 4. DÉTECTION CODE MORT ET DUPLICATION
npx jscpd . --threshold 0 --min-lines 3
npx @glen/jsinspect .
npx eslint --ext .ts,.tsx --format json src/ > lint-report.json

# 5. ANALYSE DES IMPORTS
npx organize-imports-cli tsconfig.json
npx import-sort-cli src/

# 6. VÉRIFICATION DES TESTS AVEC COVERAGE
npm test -- --coverage --watchAll=false --collectCoverageFrom="src/**/*.{ts,tsx}"

# 7. ANALYSE DE BUNDLE SIZE
npm run build
npx webpack-bundle-analyzer dist/stats.json
npx source-map-explorer 'dist/*.js'

# 8. VALIDATION FINALE
npm run build
npm test
npm run lint
```

### 4.3 Vérifications Manuelles avec Cursor (Essentielles)

**Pour CHAQUE fichier dans src/ :**

```typescript
// Dans Cursor IDE, utiliser:
// 1. Click droit > "Find All References" (Ctrl+Shift+F12)
// 2. Click droit > "Find All Implementations"
// 3. Click droit > "Go to Definition"
// 4. Multi-cursor (Ctrl+D) pour renommer cohéremment
// 5. Semantic search: "Where is this function called?"

// Questions à se poser:
// - Est-il importé quelque part ? (Find All References)
// - Est-il couvert par des tests ? (Search test files)
// - Fournit-il une valeur unique ? (Semantic search)
// - Est-il dupliqué ailleurs ? (Search codebase)
// - Respecte-t-il les conventions ? (Visual inspection)
```

### 4.4 Refactoring Automatisé avec Cursor

```typescript
// 1. RENOMMAGE MASSIF CROSS-FILE
// Sélectionner nom → Shift+F12 → Rename Symbol
// Cursor mettra à jour tous les fichiers automatiquement

// 2. EXTRACTION DE FONCTIONS
// Sélectionner code dupliqué → AI Composer
// "Extract this code into a reusable utility function"

// 3. ORGANISATION DES IMPORTS
// Ctrl+Shift+P → "Organize Imports"
// Supprime imports inutiles, organise alphabétiquement

// 4. GÉNÉRATION DE TESTS
// AI Composer: "Generate unit tests for this function with 100% coverage"
// AI Composer: "Create integration tests for this module"

// 5. RÉÉCRITURE DE CODE LEGACY
// AI Composer: "Refactor this code to use modern patterns"
// AI Composer: "Convert this callback hell to async/await"

// 6. DÉTECTION DE PERFORMANCE
// AI Composer: "Optimize this function for performance"
// AI Composer: "Identify potential memory leaks in this code"
```

### 4.5 Exploitation du Codebase Search de Cursor

```typescript
// Requêtes sémantiques puissantes:

// 1. CODE MORT
"Functions that are never called"
"Unused exports in this module"
"Dead code that can be safely removed"

// 2. DUPLICATIONS
"Similar implementations of this pattern"
"Duplicate logic across modules"
"Code that should be extracted to a utility"

// 3. ARCHITECTURE
"How is error handling implemented across the codebase?"
"What's the data flow for user authentication?"
"Where are API calls made in this application?"

// 4. OPTIMISATIONS
"Slow operations that could be memoized"
"Components that re-render unnecessarily"
"Heavy computations that should be cached"

// 5. SÉCURITÉ
"Where is user input validated?"
"How are sensitive operations protected?"
"Direct database queries without sanitization"
```

---

## ✅ PHASE 5 : CRITÈRES DE VALIDATION TOC

### 5.1 Qualité Code (Zéro Tolérance)
```
- [ ] 0 warning ESLint/Prettier (mode strict activé)
- [ ] 0 erreur TypeScript (strict mode)
- [ ] Coverage de tests ≥ 85%
- [ ] 0 duplication détectée (similarity < 5%)
- [ ] Complexité cyclomatique < 8 par fonction
- [ ] Longueur de fonction < 40 lignes
- [ ] Indentation cohérente (2 espaces ou config .editorconfig)
- [ ] Pas de console.log de debug (grep -r vérifié)
- [ ] Pas de debugger statements
- [ ] Imports triés et organisés
- [ ] Types stricts (pas de `any`, utilisation `unknown` si nécessaire)
- [ ] Pas de variables globales
- [ ] Pas de side-effects dans utils
- [ ] Tous les erreurs gérées (try-catch appropriés)
- [ ] Pas de code commenté
```

### 5.2 Structure (Perfection)
```
- [ ] Profondeur maximale de dossiers: 4 niveaux
- [ ] Un seul point d'entrée (index.ts/js)
- [ ] Pas de fichiers orphelins (vérifié avec semantic search)
- [ ] Convention de nommage respectée partout (automated check)
- [ ] Pas de dossier vide (sauf intentionnel avec .gitkeep)
- [ ] Documentation README concise et à jour
- [ ] .gitignore complet et minimal
- [ ] Pas de fichiers de plus de 300 lignes (split logique)
- [ ] Feature-based organization respectée
- [ ] Barrel exports appropriés (index.ts dans chaque dossier)
```

### 5.3 Performance
```
- [ ] Taille du bundle optimisée (webpack-bundle-analyzer)
- [ ] Pas de dépendance inutile (depcheck clean)
- [ ] Tree-shaking fonctionnel
- [ ] Lazy loading des routes/features
- [ ] Assets optimisés (compression images, fonts)
- [ ] Code splitting approprié
- [ ] Memoization où nécessaire
- [ ] Build time < 2 minutes
- [ ] Pas d'imports lourds au top-level
```

### 5.4 Tests (Couverture Maximale)
```
- [ ] Tous les tests passent (green status)
- [ ] Coverage report clair et lisible
- [ ] Tests rapides (< 30s total)
- [ ] Mocks isolés et réutilisables
- [ ] Test fixtures organisées
- [ ] Integration tests pour flow critiques
- [ ] Snapshot tests pour UI (si applicable)
- [ ] Tests de performance pour opérations lourdes
```

### 5.5 Documentation
```
- [ ] README avec sections: Description, Installation, Usage, Contributing
- [ ] API documentée avec exemples (si applicable)
- [ ] JSDoc pour fonctions publiques
- [ ] Code comments seulement pour logique complexe
- [ ] Changelog maintenu (si applicable)
- [ ] Architecture documentée (si complexe)
```

---

## 📋 PHASE 6 : CHECKLIST FINALE OBSESSIONNELLE

Avant de marquer le projet comme "propre", vérifier:

```
AUDIT COMPLET:
[ ] Tous les tests passent (green status, 0 skipped)
[ ] Build réussi sans warning (dev + prod)
[ ] Coverage report généré et ≥ 85%
[ ] Dependency graph vérifié (madge, no circular deps)
[ ] Aucun fichier inutile détecté (find + semantic search)
[ ] Bundle analyzer vérifié (pas de chunks inutiles)
[ ] Lint report clean (0 errors, 0 warnings)

STRUCTURE:
[ ] Arborescence logique et standardisée (depth ≤ 4)
[ ] Pas de dossiers vides inutiles
[ ] Nommage cohérent partout (automated verification)
[ ] README.md complet et précis (sections standard)
[ ] .gitignore à jour (pas d'assets commités)
[ ] .editorconfig présente (cohérence équipe)
[ ] Convention de commits définie (si applicable)

CODE:
[ ] 0 duplication (jscpd threshold 0)
[ ] 0 dead code (semantic search validated)
[ ] 0 imports inutiles (organize-imports check)
[ ] 0 variables non utilisées (TypeScript strict)
[ ] 0 console.log ni debugger
[ ] Linting passé à 100% (0 errors/warnings)
[ ] Types stricts partout (no any)
[ ] Error handling approprié partout
[ ] Performance optimisée (memoization, lazy loading)

DOCUMENTATION:
[ ] README avec installation et usage clair
[ ] API documentée (si applicatif, avec exemples)
[ ] Code comments essentiels uniquement
[ ] Changelog maintenu (si applicable)
[ ] Contribution guidelines (si open-source)

VALIDATION:
[ ] Projet fonctionne à 100% en dev (npm run dev)
[ ] Projet fonctionne à 100% en prod (npm run build && serve)
[ ] Pas de régression détectée (tests avant/après)
[ ] Performance non dégradée (Lighthouse/Perf audit)
[ ] Bundle size acceptable (< 500KB initial, < 1MB total)
[ ] Load time acceptable (< 3s first contentful paint)
```

---

## 🚀 PHASE 7 : AUTOMATISATION AVANCÉE

### 7.1 Scripts npm Intégrés
```json
{
  "scripts": {
    "audit": "npm audit && depcheck && unused-exports",
    "clean:prep": "find . -name '*.bak' -o -name '*.old' | xargs rm -f",
    "clean:code": "unused-exports && organize-imports-cli && eslint --fix",
    "test:coverage": "jest --coverage --watchAll=false",
    "analyze:bundle": "webpack-bundle-analyzer dist/stats.json",
    "analyze:duplication": "jscpd . --threshold 0",
    "validate:all": "npm run lint && npm run test && npm run build",
    "pre-push": "npm run validate:all"
  }
}
```

### 7.2 Pre-commit Hooks (Husky)
```bash
# Installer Husky
npm install --save-dev husky lint-staged

# Configuration .lintstagedrc
{
  "*.{ts,tsx}": [
    "eslint --fix",
    "prettier --write",
    "git add"
  ],
  "*.{json,md}": [
    "prettier --write",
    "git add"
  ]
}

# Configuration husky
npx husky install
npx husky add .husky/pre-commit "npx lint-staged"
```

### 7.3 CI/CD Pipeline (.github/workflows/ci.yml)
```yaml
name: Quality Assurance

on: [push, pull_request]

jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      
      - run: npm ci
      - run: npm run lint
      - run: npm run test:coverage
      - run: npm run build
      - run: npx depcheck
      - run: npx jscpd . --threshold 5
      
      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage/lcov.info
          flags: unittests
          name: codecov-umbrella
```

---

## 📊 PHASE 8 : RAPPORT DE PURIFICATION

Fournir un rapport détaillé final :

```markdown
# Rapport de Purification TOC - [DATE]

## 📈 Métriques Avant/Après

### Fichiers
- **Avant**: X fichiers
- **Après**: Y fichiers
- **Réduction**: -Z% (-X fichiers supprimés)

### Taille
- **Avant**: X MB
- **Après**: Y MB
- **Réduction**: -Z%

### Code
- **Lignes de code**: X → Y (-Z%)
- **Fichiers sources**: X → Y
- **Lignes de tests**: X → Y (+Z%)

### Dependencies
- **Production**: X → Y (-Z%)
- **Développement**: X → Y (-Z%)
- **Total**: X → Y (-Z%)

### Performance
- **Bundle size**: X KB → Y KB (-Z%)
- **Build time**: Xs → Ys (-Z%)
- **Coverage**: X% → Y% (+Z%)

## 🗑️ Éléments Supprimés

### Fichiers
- X fichiers de backup
- X fichiers de code mort
- X fichiers de configuration inutiles
- X assets non référencés

### Code
- X lignes de code mort
- X fonctions non utilisées
- X exports jamais importés
- X lignes de code dupliquées

### Dépendances
- X packages de production
- X packages de développement
- X packages obsolètes

## ✨ Améliorations Apportées

### Architecture
- ✅ Restructuration en feature-based architecture
- ✅ Implémentation de barrel exports
- ✅ Séparation claire core/shared/features
- ✅ Réduction de profondeur (max 4 niveaux)

### Code Quality
- ✅ TypeScript strict mode activé
- ✅ ESLint/Prettier configuré strictement
- ✅ Suppression de toutes duplications
- ✅ Optimisation des imports
- ✅ Error handling amélioré

### Performance
- ✅ Bundle size réduit de X%
- ✅ Code splitting optimisé
- ✅ Lazy loading des routes
- ✅ Memoization des composants lourds
- ✅ Tree-shaking optimisé

### Tests
- ✅ Coverage augmenté à X%
- ✅ Tests rapides et fiables
- ✅ Mocks centralisés
- ✅ Fixtures réutilisables

### Documentation
- ✅ README complet et à jour
- ✅ API documentée (si applicable)
- ✅ JSDoc pour fonctions publiques
- ✅ Contribution guidelines clarifiées

## 📊 Analyses de Qualité

### Avant
- ESLint errors: X
- ESLint warnings: Y
- TypeScript errors: X
- Code duplication: X%
- Coverage: X%

### Après
- ESLint errors: 0 ✅
- ESLint warnings: 0 ✅
- TypeScript errors: 0 ✅
- Code duplication: 0% ✅
- Coverage: X% ✅

## 🎯 Prochaines Étapes Recommandées

- [ ] Monitoring de performance en production
- [ ] Mise en place de tests E2E (si applicable)
- [ ] Optimisation progressive des images
- [ ] Mise en place de monitoring d'erreurs (Sentry)
- [ ] Documentation approfondie de l'architecture

## ✅ État Final

**Projet certifié "production-ready" et "TOC-compliant"**

✅ Tous les critères TOC validés
✅ Arborescence ultra-professionnelle
✅ Code maintenable, scalable et performant
✅ Tests exhaustifs et coverage élevé
✅ Documentation minimale mais complète
✅ Performance optimisée
✅ Best practices respectées partout

**Ready to ship! 🚀**
```

---

## 📊 PHASE 9 : MÉTRIQUES DE COMPLEXITÉ AVANCÉES

### 9.1 Cyclomatic Complexity (NASA Standard)
```bash
# Outil: complexity-report
npm install --save-dev complexity-report

# Configuration
npx cr src/ --format json > complexity-report.json

# Seuils critiques
# - Fonction: complexité ≤ 10 (objectif : ≤ 5)
# - Méthode: complexité ≤ 8 (objectif : ≤ 4 acceptable)
# - Classe: complexité ≤ 50 (objectif : ≤ 20)
```

### 9.2 Cognitive Complexity (SonarQube)
```bash
# Détection des opérateurs logiques imbriqués
npx eslint --rule 'complexity: ["error", 10]'
npx eslint --rule 'max-depth: ["error", 4]'
npx eslint --rule 'max-lines-per-function: ["error", 40]'
npx eslint --rule 'max-params: ["error", 4]'
```

### 9.3 Maintainability Index (ISO/IEC 9126)
```typescript
// Formule: MI = 171 - 5.2 * ln(H) - 0.23 * C - 16.2 * ln(LOC)
// Où:
// H = Halstead Volume
// C = Cyclomatic Complexity
// LOC = Lines of Code

// Seuils MI:
// 0-65: Coûteux à maintenir
// 66-85: Acceptable
// 86-100: Excellent (objectif TOC: ≥ 90)
```

### 9.4 Dette Technique (SonarQube)
```bash
# Installation SonarQube
docker run -d -p 9000:9000 sonarqube

# Analyse
npx sonar-scanner \
  -Dsonar.projectKey=my-project \
  -Dsonar.sources=src \
  -Dsonar.host.url=http://localhost:9000

# Métriques de dette
# - Technical Debt Ratio: < 5% (objectif: < 2%)
# - Code Smells: 0 (tolérance < 5)
# - Hotspots: Audit complet requis
```

### 9.5 Coupling Metrics
```bash
# Efferent Coupling (sortant)
npx madge --json --circular src/ > coupling-report.json

# Seuils critiques
# - Module coupling: ≤ 5 dépendances
# - Circular dependencies: 0 (tolérance: 0)
# - Package coupling: ≤ 10 modules
```

---

## 🔍 PHASE 10 : ANALYSE STATIQUE ET DYNAMIQUE

### 10.1 Outils Statiques Avancés
```bash
# 1. PLATO - Analyse de complexité JavaScript
npm install --save-dev plato
npx plato -r -d ./report src/

# 2. ESLint avec règles custom
npm install --save-dev @typescript-eslint/eslint-plugin
# Activer règles sécurité, performance, best practices

# 3. ESLint Security Plugin
npm install --save-dev eslint-plugin-security
# Détecte: eval(), innerHTML, nonce manquant, etc.

# 4. ESLint SonarJS
npm install --save-dev eslint-plugin-sonarjs
# Détecte patterns suspects, bugs, code smells

# 5. ESLint Node
npm install --save-dev eslint-plugin-node
# Vérifie patterns Node.js spécifiques
```

### 10.2 Analyse Dynamique (Runtime)
```bash
# 1. Memory Leaks Detection
npm install --save-dev leak-detector

# 2. CPU Profiling
node --prof index.js
node --prof-process isolate*.log > profile.txt

# 3. Chrome DevTools Performance
npm install --save-dev chrome-har-capture

# 4. Lighthouse CI (Continuous Performance)
npm install --save-dev @lhci/cli
lhci autorun

# 5. Clarity (Microsoft) - User Behavior
# Intégrer dans index.html
```

### 10.3 Fuzzing et Testing Avancé
```bash
# 1. Property-Based Testing (Fast-Check)
npm install --save-dev fast-check

# Exemple test
import fc from 'fast-check';
test('addition commutativity', () => {
  fc.assert(fc.property(fc.integer(), fc.integer(), (a, b) => {
    return add(a, b) === add(b, a);
  }));
});

# 2. Mutation Testing (Stryker)
npm install --save-dev @stryker-mutator/core
npx stryker run

# 3. Contract Testing (Pact)
npm install --save-dev @pact-foundation/pact
```

### 10.4 Audit de Sécurité
```bash
# 1. OWASP Dependency Check
npm install --save-dev audit
npm audit --production
npm audit fix

# 2. Snyk
npm install --save-dev snyk
npx snyk test
npx snyk monitor

# 3. Retire.js (vulnérabilités JS)
npm install --save-dev retire

# 4. Bundle Analysis Security
npx npm-audit --production
npx depcheck --ignores="*test*"
```

---

## ⚠️ PHASE 11 : DÉTECTION D'ANTI-PATTERNS

### 11.1 Anti-Patterns JavaScript/TypeScript
```typescript
// ❌ ANTI-PATTERNS À éliminer

// 1. Callback Hell
fs.readFile('a.txt', (err, data) => {
  fs.readFile('b.txt', (err, data) => {
    fs.readFile('c.txt', (err, data) => {
      // ...
    });
  });
});
// ✅ Solution: async/await ou Promise.all

// 2. Magic Numbers
if (users.length > 5) { // ❌
  sendEmail();
}
const MAX_USERS_FOR_EMAIL = 5;
if (users.length > MAX_USERS_FOR_EMAIL) { // ✅

// 3. God Objects
class App {
  // 50+ méthodes, mélange de responsabilités
}
// ✅ Solution: Single Responsibility Principle

// 4. Parallel Inheritance Hierarchies
class Rectangle {
  drawRectangle() { }
  // Nécessite toujours WindowRectangle...
}
// ✅ Solution: Composition over Inheritance

// 5. Spaghetti Code
// Fonctions de 200+ lignes, pas de structure
// ✅ Solution: Refactoring en petites fonctions

// 6. Premature Optimization
function calculate() {
  // Optimisation micro avant profiling
}
// ✅ Solution: Profile d'abord, optimise ensuite

// 7. Swiss Army Knife Functions
function doEverything(p1, p2, p3, p4, p5, p6) {
  // 15 paramètres, 20 if/else imbriqués
}
// ✅ Solution: Séparation en fonctions dédiées

// 8. Copy-Paste Programming
// Code dupliqué partout
// ✅ Solution: Extraction en utilitaires

// 9. Primitive Obsession
const email = "user@example.com"; // string partout
// ✅ Solution: Value Objects (Email class)

// 10. Feature Envy
class Order {
  calculateTotal() {
    return this.items.reduce((sum, item) => {
      return sum + item.price * item.quantity; // Accès répété à item
    }, 0);
  }
}
// ✅ Solution: Déplacer logique vers Item
```

### 11.2 Anti-Patterns React/UI
```typescript
// ❌ Props Drilling (10 niveaux de props)
function App() {
  return <Child data={data} />
}
function Child() {
  return <GrandChild data={data} />
}
// ✅ Solution: Context API ou State Management

// ❌ Inline Functions in JSX
<button onClick={() => handleClick(id)}> // ❌
// ✅ Solution: useCallback

// ❌ State in Component (non lifté)
function Modal() {
  const [isOpen, setIsOpen] = useState(false);
  // Modal ne devrait pas gérer son propre état
}
// ✅ Solution: Controlled component

// ❌ useEffect without Dependencies
useEffect(() => {
  fetchData();
}, []); // ❌ Missing dependencies
// ✅ Solution: eslint-plugin-react-hooks
```

### 11.3 Anti-Patterns Performance
```typescript
// ❌ N+1 Queries
users.forEach(user => {
  const posts = fetchUserPosts(user.id); // ❌
});
// ✅ Solution: Batch queries

// ❌ Unnecessary Re-renders
function Component({ data }) {
  const processed = data.map(x => x * 2); // ❌ Re-compute à chaque render
  return <div>{processed}</div>;
}
// ✅ Solution: useMemo

// ❌ Large Bundle
import { everything } from 'huge-library';
// ✅ Solution: Tree-shaking, code splitting
```

### 11.4 Requêtes Cursor pour Détecter Anti-Patterns
```
"Callback hell in async operations"
"Nested ternary operators"
"Long parameter lists"
"Deep inheritance hierarchies"
"Functions with too many responsibilities"
"Unused state or props"
"Missing error boundaries"
"Inline styles or complex CSS-in-JS"
"Hardcoded configuration values"
"Circular dependencies between modules"
```

---

## 📤 PHASE 12 : RAPPORTS STRUCTURÉS ET AUTOMATISATION

### 12.1 Format de Sortie JSON
```bash
# Générer rapport JSON standardisé
node scripts/generate-report.js > reports/cleanup-report.json

# Structure du rapport
{
  "metadata": {
    "timestamp": "2024-01-15T10:30:00Z",
    "version": "2.0",
    "project": "my-awesome-project",
    "hash": "abc123..."
  },
  "metrics": {
    "before": {
      "files": 456,
      "lines": 12000,
      "size": "45 MB",
      "dependencies": 87
    },
    "after": {
      "files": 312,
      "lines": 8900,
      "size": "32 MB",
      "dependencies": 71
    },
    "reduction": {
      "files": -31.6,
      "lines": -25.8,
      "size": -28.9,
      "dependencies": -18.4
    }
  },
  "removals": {
    "files": [
      { "path": "src/utils/old-helper.ts", "reason": "unused", "confidence": 0.95 },
      { "path": "src/components/LegacyModal.tsx", "reason": "deprecated", "confidence": 1.0 }
    ],
    "code": {
      "dead": 234,
      "duplicated": 189,
      "commented": 45
    }
  },
  "refactoring": [
    {
      "file": "src/services/auth.ts",
      "type": "extract_function",
      "description": "Extracted login logic into separate function"
    }
  ],
  "tests": {
    "coverage": {
      "before": 72,
      "after": 87,
      "delta": +15
    },
    "passed": 156,
    "failed": 0,
    "skipped": 3
  },
  "quality": {
    "eslint_errors": 0,
    "typescript_errors": 0,
    "complexity_avg": 4.2,
    "maintainability_index": 92
  },
  "next_steps": [
    "Review security audit",
    "Optimize bundle size",
    "Add E2E tests"
  ]
}
```

### 12.2 XML (pour outils externes)
```xml
<?xml version="1.0" encoding="UTF-8"?>
<cleanup-report>
  <project>my-awesome-project</project>
  <timestamp>2024-01-15T10:30:00Z</timestamp>
  <metrics>
    <files deleted="144" kept="312"/>
    <lines removed="3100" kept="8900"/>
    <complexity reduced="18%"/>
  </metrics>
  <warnings>
    <warning level="low">Minor: Some TODO comments remain</warning>
  </warnings>
</cleanup-report>
```

### 12.3 Markdown Structuré (lisible)
```markdown
# Cleanup Report for my-awesome-project
Generated: 2024-01-15 10:30:00 UTC

## Summary
- **Files**: 456 → 312 (-31.6%)
- **Lines**: 12000 → 8900 (-25.8%)
- **Size**: 45 MB → 32 MB (-28.9%)

## Quality Improvements
- ESLint: 0 errors ✅
- TypeScript: 0 errors ✅
- Coverage: 72% → 87% (+15%)
- Maintainability: 92/100

## Removed Files
1. `src/utils/old-helper.ts` (unused)
2. `src/components/LegacyModal.tsx` (deprecated)
...
```

---

## 🧪 PHASE 13 : TESTS DE NON-RÉGRESSION

### 13.1 Test Suite du Prompt Lui-Même
```bash
# Créer tests pour valider le prompt TOC
mkdir -p tests/prompt

# test-prompt-efficiency.spec.js
describe('TOC Prompt Efficiency', () => {
  it('should detect all dead code', async () => {
    const results = await runPromptOnSampleProject();
    expect(results.deadCode.files).toHaveLength(5);
  });

  it('should not remove test files', async () => {
    const results = await runPromptOnSampleProject();
    expect(results.removedFiles).not.toContain('*.test.ts');
  });

  it('should maintain 100% test coverage', async () => {
    const coverage = await runPromptOnSampleProject();
    expect(coverage.coverage).toBeGreaterThanOrEqual(80);
  });
});
```

### 13.2 Golden Files (Référence de Qualité)
```bash
# Stocker des "golden" reports de référence
mkdir -p tests/prompt/golden-reports

# golden-report-v1.0.json
{
  "standard": {
    "max_files": 400,
    "max_complexity": 8,
    "min_coverage": 85
  },
  "examples": [
    "example-project-1-clean.json",
    "example-project-2-clean.json"
  ]
}
```

### 13.3 Validation Algorithmique
```python
# Script de validation du prompt
def validate_prompt_execution(report):
    assert report['metrics']['reduction']['files'] < 0, "No files removed"
    assert report['quality']['coverage'] >= 80, "Low coverage"
    assert report['quality']['eslint_errors'] == 0, "Lint errors remain"
    assert report['quality']['complexity_avg'] < 8, "High complexity"
    return True
```

---

## 🛡️ PHASE 14 : MODE "TOC-SAFE" (Sécurité Totale)

### 14.1 Double Vérification Obligatoire
```bash
# Mode TOC-Safe: Toujours vérifier 2x avant suppression
CURSOR_MODE=toc-safe ./cleanup.sh

# Flow de validation
1. Détection initiale (avec prudence)
2. Semantic search CURSOR (validation)
3. AI Review (confirmation)
4. Manuelle review (dernière vérification)
5. Backup avant chaque suppression
6. Rollback automatique si regression
```

### 14.2 Dry-Run Mode
```bash
# Toujours tester en mode dry-run d'abord
./cleanup.sh --dry-run > dry-run-report.json

# Analyse du dry-run
node scripts/analyze-dry-run.js dry-run-report.json

# Déterminer sécurité de chaque changement
# - HIGH RISK: Ne pas appliquer automatiquement
# - MEDIUM RISK: Demander confirmation
# - LOW RISK: Appliquer avec monitoring
```

### 14.3 Rollback Automatique
```bash
# Créer checkpoint avant chaque batch
git tag checkpoint-before-cleanup-v1

# Si regression détectée
npm test -- --bail  # S'arrête au premier échec
if [ $? -ne 0 ]; then
  git reset --hard checkpoint-before-cleanup-v1
  git tag -d checkpoint-before-cleanup-v1
  notify "Rollback performed due to test failure"
fi
```

### 14.4 Gradual Application
```bash
# Ne pas tout nettoyer d'un coup
# Appliquer par module/feature

./cleanup.sh --scope=src/features/auth
npm test # Vérifier
git commit -m "Cleanup: auth feature"

./cleanup.sh --scope=src/shared
npm test # Vérifier
git commit -m "Cleanup: shared utilities"

# Continue module par module
```

### 14.5 Confidence Scoring
```bash
# Chaque suppression a un score de confiance
{
  "file": "src/utils/old.ts",
  "confidence": 0.95,  # 95% sûr que c'est safe
  "reasons": [
    "Not imported anywhere",
    "No tests reference it",
    "Unused in semantic search"
  ],
  "risk": "LOW",
  "action": "DELETE"  # ou "REVIEW" si confidence < 0.9
}
```

---

## 📜 PHASE 15 : STANDARDS INDUSTRIELS (ISO 5055, MISRA, NASA)

### 15.1 ISO/IEC 5055 (Software Quality)
```bash
# Métriques ISO 5055 (ancien ISO 5055-2014)
npx sonarqube-scanner -Dsonar.qualitygate.wait=true

# Critères ISO 5055:
# 1. Maintainability (ISO 5055-1)
# 2. Reliability (ISO 5055-2)
# 3. Performance Efficiency (ISO 5055-3)
# 4. Security (ISO 5055-4)

# Thresholds
# - Maintainability Index: ≥ 80
# - Reliability Level: ≥ HIGH (≤ 1 bug/KLOC)
# - Performance: Responsive (< 100ms)
# - Security: No Critical vulnerabilities
```

### 15.2 MISRA C/C++ (adaptions JS/TS)
```typescript
// ❌ MISRA Violations (à éviter absolument)

// Rule 8.5: No external declarations without external linkage
var globalVar = 10; // ❌
// ✅ const LOCAL_CONST = 10;

// Rule 16.3: No unconditional jumps (goto, break, continue excessive)
while (true) {
  if (condition) continue; // ❌ Excessive
}
// ✅ Refactor avec early return

// Rule 17.5: No function return values ignored
someFunction(); // ❌ Return ignored
// ✅ const result = someFunction();

// Rule 21.1: No unbounded functions (eval, setTimeout with string)
eval(code); // ❌
// ✅ Use Function constructor or parser

// ESLint MISRA Plugin
npm install --save-dev eslint-plugin-misra
```

### 15.3 NASA Coding Standards
```typescript
// NASA Power-of-10 Rules (adapté JS/TS)

// 1. No more than 10 paths through a function
function process() {
  if (...) { }
  if (...) { }  // ❌ 15+ paths
  // ...
}

// 2. Variable scope limited to 10 lines
function foo() {
  const a = ...; // Line 1
  const b = ...; // Line 2
  // ...
  // Use 'a' again on line 45 ❌
}

// 3. No more than 10 levels of nesting
if () {
  if () {
    if () {
      if () {
        if () { // ❌ 5 levels
          if () { }
        }
      }
    }
  }
}

// 4. All loops bounded (max 10 iterations or explicit bound)
for (let i = 0; i < items.length; i++) { // ✅ Bounded
}
while (true) { // ❌ Unbounded
}

// 5. All memory allocated statically (no dynamic allocation)
const arr = []; // ✅ Pre-allocated size possible
const arr = new Array(10); // ✅ Static allocation
```

### 15.4 Checklist ISO 5055 / MISRA / NASA
```
QUALITÉ (ISO 5055-1):
[ ] Maintainability Index ≥ 80
[ ] Code Duplication < 3%
[ ] Cyclomatic Complexity ≤ 10 (≤ 5 ideal)
[ ] 0 violation de conventions
[ ] Documentation coverage ≥ 80%

FIABILITÉ (ISO 5055-2):
[ ] No unhandled exceptions
[ ] All edge cases tested
[ ] Error logging implemented
[ ] Graceful degradation

PERFORMANCE (ISO 5055-3):
[ ] Response time < 100ms (API)
[ ] No memory leaks
[ ] Efficient algorithms (Big-O optimal)
[ ] Resource usage bounded

SÉCURITÉ (ISO 5055-4):
[ ] No hardcoded secrets
[ ] Input validation everywhere
[ ] Output sanitization
[ ] Security headers configured

MISRA (Adapté):
[ ] No eval() or similar
[ ] No global variables
[ ] Explicit bounds checking
[ ] All loops bounded
[ ] No recursion > 5 levels

NASA (Adapté):
[ ] Max 10 paths per function
[ ] Max 10 levels nesting
[ ] All loops bounded
[ ] No dynamic memory (where possible)
[ ] No goto statements
```

---

## 🔄 PHASE 16 : PROMPTS ITÉRATIFS ET DÉTERMINISTES

### 16.1 Prompts avec Etat (State Management)
```json
{
  "prompt_version": "2.1.0",
  "execution_id": "cleanup-2024-01-15-abc123",
  "state": {
    "last_run": "2024-01-14T10:00:00Z",
    "files_analyzed": 456,
    "files_removed": 144,
    "checkpoints": [
      {
        "id": "checkpoint-1",
        "timestamp": "2024-01-15T09:00:00Z",
        "scope": "src/shared",
        "status": "completed"
      }
    ]
  },
  "next_steps": [
    "Analyze src/features/dashboard",
    "Review security audit"
  ]
}
```

### 16.2 Prompts Idempotents
```bash
# Même prompt, même résultat (même si exécuté 2x)
./cleanup.sh --idempotent

# Idempotence garantie via:
1. Hashing des états
2. Vérification avant action
3. No-op si déjà appliqué
4. Deterministic ordering
```

### 16.3 Prompts Composable
```yaml
# Prompt comme composition de sous-prompts
prompts:
  - name: detect-dead-code
    file: prompts/detect-dead-code.yml
    dependencies: []
  
  - name: remove-duplications
    file: prompts/remove-duplications.yml
    dependencies: [detect-dead-code]
  
  - name: optimize-imports
    file: prompts/optimize-imports.yml
    dependencies: [detect-dead-code]

# Exécution orchestrée
./run-prompt-suite prompts/toc-cleanup-suite.yml
```

### 16.4 Versioning des Prompts
```bash
# Versioning semantique pour prompts
# prompt-version: 2.1.0-major.minor.patch

# Changelog des prompts
# CHANGELOG_PROMPTS.md:
# - v2.1.0: Added NASA standards compliance
# - v2.0.0: Major rewrite with modularity
# - v1.5.0: Added security hardening variant
```

### 16.5 Rollback de Prompt
```bash
# Si nouveau prompt casse quelque chose
# prompt-rollback --version 2.0.0

# Restaurer version antérieure
# git checkout prompts/v2.0.0/
# ./cleanup.sh
```

---

## 🚨 RÈGLES ABSOLUES TOC

```
1. TOUJOURS créer un backup complet avant toute suppression
2. NE JAMAIS supprimer sans vérifier avec semantic search
3. TOUJOURS vérifier les dépendances avant suppression
4. TOUJOURS s'assurer que dev/test/build fonctionnent
5. NE JAMAIS supprimer les logs d'audit système
6. CONSERVER l'historique git propre (commits atomiques)
7. VALIDATION par au moins 2 commandes de check
8. DOCUMENTATION de chaque suppression significative
9. TESTS AVANT/APRÈS pour chaque refactoring majeur
10. REVIEW de chaque changement avec semantic search
```

---

## 🎯 WORKFLOW CURSOR IDE OPTIMISÉ

### 1. Ouverture du Projet
```
- Ouvrir le workspace dans Cursor
- Attendre l'indexation complète
- Vérifier les liens symboliques
```

### 2. Semantic Search pour Audit
```
- "Où est utilisé ce module ?"
- "Quelles sont les duplications de ce pattern ?"
- "Code mort dans ce fichier ?"
```

### 3. Refactoring Automatisé
```
- Rename Symbol (Shift+F12)
- Extract Function/Component
- AI Composer pour génération
- Multi-cursor pour modifications massives
```

### 4. Validation Continue
```
- Run tests (Cmd/Ctrl+P → "Run Test")
- Check references (Shift+F12)
- Format document (Shift+Alt+F)
- Organize imports (Cmd/Ctrl+Shift+P)
```

---

## ⚠️ EDGE CASES À GÉRER

### Configuration Spécifique
- **Monorepo**: Appliquer le prompt dans chaque workspace
- **Serverless**: Vérifier taille de handlers individuellement
- **Mobile**: Optimiser pour bundle native
- **Microservices**: Auditer chaque service séparément

### Frameworks Spécifiques
- **Next.js**: Vérifier image optimization, API routes
- **Vue**: Optimiser composants, Pinia stores
- **Angular**: Tree-shaking, lazy modules
- **Svelte**: Component size, tree-shaking
- **Remix**: Optimiser loaders, actions

### Dépendances Sensibles
- **Security packages**: Ne jamais supprimer sans vérification
- **Polyfills**: Vérifier support navigateur cible
- **Type definitions**: Garder @types packages nécessaires
- **Peer dependencies**: Vérifier compatibilité

---

## 🔧 TROUBLESHOOTING

### "J'ai supprimé un fichier mais le build casse"
```bash
# Solution
1. Vérifier avec semantic search avant suppression
2. Regarder l'erreur de build pour identifier le lien
3. Restaurer depuis git si nécessaire: git checkout path/to/file
4. Analyser les dépendances: npx madge src/
```

### "Coverage baisse après nettoyage"
```bash
# Solution
1. Régénérer tests pour code gardé
   npm test -- --coverage --coveragePathIgnorePatterns=[]
2. Ajouter tests manquants avec AI Composer
3. Vérifier les tests skipés: npm test -- --verbose
```

### "Bundle size augmente paradoxalement"
```bash
# Solution
1. Analyser avec webpack-bundle-analyzer
2. Vérifier imports dupliqués dans package.json
3. Chercher dynamiques imports manqués
4. Vérifier tree-shaking config
```

### "Tests deviennent instables"
```bash
# Solution
1. Isoler les mocks manquants
   npx jest --listTests | grep [pattern]
2. Vérifier fixtures non supprimées
3. Analyser les tests avec --verbose
4. Vérifier les timeouts et flaky tests
```

### "Semantic search ne trouve pas les usages"
```bash
# Solution
1. Vérifier que l'indexation Cursor est complète
2. Utiliser grep comme fallback: grep -r "functionName" src/
3. Vérifier les alias d'imports dans tsconfig.json
4. Utiliser Find All References (Shift+F12) en fallback
```

---

## 🚀 QUICK START

### Installation Rapide
```bash
# 1. Installer les outils
npm install --save-dev \
  depcheck \
  unused-exports \
  madge \
  jscpd \
  webpack-bundle-analyzer \
  husky \
  lint-staged

# 2. Créer un backup
tar -czf backup_$(date +%Y%m%d).tar.gz . \
  --exclude=node_modules --exclude=dist --exclude=.git
```

### Workflow Express (30 minutes)
```bash
# 1. Audit initial
npm run audit
npm run analyze:duplication

# 2. Nettoyage automatique
npm run clean:prep
npm run clean:code

# 3. Vérification
npm test -- --coverage
npm run build

# 4. Validation finale
npm run validate:all
```

### Checklist Express (5 min après nettoyage)
```
- [ ] Tests passent
- [ ] Build réussi
- [ ] 0 ESLint errors
- [ ] Coverage > 80%
- [ ] Bundle size acceptable
```

---

## 🎯 VARIANTES DE PROMPT

### Variante 1 : Performance-First

#### Metrics Prioritaires
```markdown
- Bundle size < 300KB initial
- Lighthouse Performance > 90
- First Contentful Paint < 1.5s
- Time to Interactive < 3s
- Cumulative Layout Shift < 0.1
```

#### Recherches Cursor Spécifiques
```
"Lazy loading opportunities in routes"
"Images not optimized or not using next/image"
"Large dependencies that could be code-split"
"Heavy computations in render functions"
"Unnecessary re-renders in components"
```

#### Optimisations Automatiques
```bash
# Code splitting par route automatique
# Tree-shaking agressif des libs
# Compression des assets (imagemin, svgo)
# Preconnect pour domaines externes
# Memoization des composants React
```

### Variante 2 : Legacy Modernization

#### Détection de Patterns Obsolètes
```
"jQuery usage in modern React codebase"
"Legacy callback patterns"
"Old-style imports (require vs import)"
"Deprecated API usage"
"Promise chains that could be async/await"
```

#### Migration Automatique
```typescript
// Convertir callbacks → async/await
// Moderniser les imports (ES6 modules)
// Remplacer jQuery par vanilla JS
// Upgrader les API dépréciées
// Convertir classes → hooks (si applicable)
```

### Variante 3 : Security Hardening

#### Vérifications de Sécurité
```
"Where is user input validated?"
"Direct database queries without sanitization"
"Secrets committed in code"
"Unsafe eval or innerHTML usage"
"CSRF protection implementation"
"XSS vulnerabilities in components"
```

#### Action Requise
- Sanitize tous les inputs utilisateur
- Implémenter rate limiting
- Vérifier les secrets dans le code
- Auditer les permissions
- Review les CSP headers

---

## 👥 MODE COLLABORATIF (Pour équipes)

### Workflow Git Optimal
```
1. Créer branche: feature/toc-cleanup-[module]
2. Appliquer le prompt sur un sous-module
3. Créer PR avec rapport de purification
4. Code review focus sur:
   - Pas de suppression de fonctionnalité
   - Tests toujours passants
   - Architecture cohérente
```

### Checklist Team
```
- [ ] Tous les devs sont alignés sur l'architecture
- [ ] Convention de nommage validée
- [ ] Standards qualité définis
- [ ] Pre-commit hooks installés pour tous
- [ ] CI/CD vérifie les nouvelles règles
- [ ] Monitoring en place pour performance
```

### Communication
```markdown
# Exemple PR Template

## 🧹 Purification TOC - Module: [nom]

### Métriques
- Fichiers: X → Y (-Z%)
- Coverage: X% → Y%
- Bundle: X → Y KB

### Changements
- [ ] Architecture restructurée
- [ ] Code mort supprimé
- [ ] Tests ajoutés

### À Vérifier
- Pas de régression fonctionnelle
- Performance maintenue ou améliorée
- Documentation à jour
```

---

## 📊 MÉTRIQUES DE SUCCÈS

### Indicateurs Clés
- **Taille du projet**: Réduction de 20-30% cible
- **Temps de build**: < 2 minutes
- **Coverage**: ≥ 85%
- **Duplication**: 0%
- **Dépendances**: -10 à -20% selon contexte
- **Temps de review**: -30% (code plus clair)

### Métriques Qualité
- Maintainability Index: A
- Technical Debt: Minimal
- Code Smell: 0 détecté
- Cognitive Complexity: Faible
- Test Quality: Excellence

---

## 🎓 RESSOURCES COMPLÉMENTAIRES

### Outils Recommandés
- **SonarQube**: Analyse statique de code
- **CodeClimate**: Mesure de la dette technique
- **BundlePhobia**: Analyse des dépendances
- **Lighthouse CI**: Performance monitoring
- **Codecov**: Tracking de couverture

### Documentation de Référence
- Clean Code by Robert C. Martin
- Refactoring by Martin Fowler
- TypeScript Handbook (strict mode)
- Web.dev Performance Best Practices

---

**FIN DU PROMPT**

**Le TOC au service de la perfection absolue.** 🔥⚡✨

*P.S. Copiez ce prompt dans Cursor IDE AI Composer pour commencer le nettoyage maniaque !*
