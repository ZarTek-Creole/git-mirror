# Exemples d'Utilisation - Git Mirror

## Exemples Basiques

### 1. Cloner tous les dépôts d'un utilisateur

```bash
./git-mirror.sh users octocat
```

### 2. Cloner avec authentification

```bash
export GITHUB_TOKEN="ghp_votre_token"
./git-mirror.sh users octocat
```

### 3. Cloner dans un répertoire spécifique

```bash
./git-mirror.sh users octocat --dest ./my-repos
```

## Exemples Avancés

### 4. Mode Parallèle avec Filtrage

```bash
./git-mirror.sh users octocat \
  --parallel --jobs 8 \
  --exclude-forks \
  --filter "project-*" \
  --dest ./projects
```

### 5. Synchronisation Incrémentale

```bash
# Première exécution - clone tout
./git-mirror.sh users octocat --incremental

# Exécutions suivantes - met à jour seulement les modifiés
./git-mirror.sh users octocat --incremental
```

### 6. Backup Complet avec Métriques

```bash
./git-mirror.sh orgs github \
  --dest ./backups/github \
  --parallel --jobs 10 \
  --metrics --metrics-format html \
  --metrics-file report.html \
  --incremental
```

### 7. Clonage Sélectif Interactif

```bash
./git-mirror.sh users octocat \
  --interactive \
  --dest ./selected
```

### 8. Clonage Shallow Rapide

```bash
./git-mirror.sh users octocat \
  --depth 1 \
  --filter "blob:none" \
  --parallel --jobs 12
```

### 9. Synchronisation avec Hooks

```bash
# Créer un hook post-clone
cat > hooks/post-clone.sh <<'EOF'
#!/bin/bash
echo "Repository $1 cloned to $2"
# Faire quelque chose avec le dépôt cloné
EOF
chmod +x hooks/post-clone.sh

export HOOKS_ENABLED=true
./git-mirror.sh users octocat
```

### 10. Mode Dry-Run pour Tester

```bash
./git-mirror.sh users octocat \
  --dry-run \
  --verbose 3
```

## Scénarios d'Utilisation

### Scénario A: Backup Quotidien

```bash
#!/bin/bash
# backup-daily.sh

USER="octocat"
BACKUP_DIR="./backups/$(date +%Y-%m-%d)"
METRICS_FILE="./metrics/$(date +%Y-%m-%d).json"

export GITHUB_TOKEN="ghp_votre_token"

./git-mirror.sh users "$USER" \
  --dest "$BACKUP_DIR" \
  --incremental \
  --parallel --jobs 8 \
  --metrics --metrics-format json \
  --metrics-file "$METRICS_FILE" \
  --quiet
```

### Scénario B: Migration de Dépôts

```bash
#!/bin/bash
# migrate-repos.sh

SOURCE_ORG="old-org"
DEST_ORG="new-org"

# Cloner depuis l'ancienne organisation
./git-mirror.sh orgs "$SOURCE_ORG" \
  --dest ./migration-src \
  --exclude-forks

# Les dépôts sont maintenant dans ./migration-src
# Vous pouvez les pousser vers la nouvelle organisation
```

### Scénario C: Analyse de Code

```bash
#!/bin/bash
# analyze-all-repos.sh

ORG="my-org"

# Cloner tous les dépôts
./git-mirror.sh orgs "$ORG" \
  --dest ./analysis \
  --filter "blob:none" \
  --depth 1

# Analyser chaque dépôt
for repo in ./analysis/*; do
    echo "Analyzing $repo"
    # Votre script d'analyse ici
done
```

### Scénario D: Synchronisation Continue

```bash
#!/bin/bash
# sync-continuous.sh

while true; do
    ./git-mirror.sh users octocat \
      --incremental \
      --quiet
    
    sleep 3600  # Attendre 1 heure
done
```

## Intégration CI/CD

### GitHub Actions

```yaml
name: Backup Repositories

on:
  schedule:
    - cron: '0 2 * * *'  # Tous les jours à 2h

jobs:
  backup:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Install dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y jq curl git parallel
      
      - name: Run git-mirror
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          chmod +x git-mirror.sh
          ./git-mirror.sh users octocat \
            --dest ./backups \
            --incremental \
            --metrics --metrics-format json
      
      - name: Upload backups
        uses: actions/upload-artifact@v2
        with:
          name: backups
          path: ./backups
```

## Astuces et Conseils

### 1. Optimiser pour Grands Volumes

```bash
# Utiliser le mode parallèle avec beaucoup de jobs
./git-mirror.sh orgs large-org \
  --parallel --jobs 20 \
  --depth 1 \
  --filter "blob:none"
```

### 2. Éviter les Limites API

```bash
# Utiliser un token avec beaucoup de requêtes
export GITHUB_TOKEN="ghp_token_avec_beaucoup_de_requêtes"
./git-mirror.sh users user \
  --cache-ttl 86400  # Cache de 24h
```

### 3. Résumer après Interruption

```bash
# Si interrompu, reprendre où on s'est arrêté
./git-mirror.sh users octocat --resume
```

### 4. Tester Avant d'Exécuter

```bash
# Toujours tester avec dry-run d'abord
./git-mirror.sh users octocat --dry-run --verbose 2
```
