#!/bin/bash

# Configuration de sécurité Bash
set -euo pipefail

# lib/metrics/metrics.sh - Module de métriques et statistiques
# Collecte et exporte les métriques d'exécution

# Variables de configuration
METRICS_ENABLED="${METRICS_ENABLED:-false}"
METRICS_FILE="${METRICS_FILE:-}"
METRICS_FORMAT="${METRICS_FORMAT:-json}"  # json ou csv

# Variables de métriques
METRICS_START_TIME=""
METRICS_END_TIME=""
METRICS_TOTAL_REPOS=0
METRICS_CLONED=0
METRICS_UPDATED=0
METRICS_FAILED=0
METRICS_TOTAL_SIZE=0
METRICS_REPO_TIMES=()

# Initialise le module de métriques
metrics_init() {
    # Réinitialiser les métriques
    METRICS_START_TIME=""
    METRICS_END_TIME=""
    METRICS_TOTAL_REPOS=0
    METRICS_CLONED=0
    METRICS_UPDATED=0
    METRICS_FAILED=0
    METRICS_TOTAL_SIZE=0
    METRICS_REPO_TIMES=()
    
    log_debug "Module de métriques initialisé"
}

# Démarre la collecte de métriques
metrics_start() {
    METRICS_START_TIME=$(date +%s)
    log_debug "Collecte de métriques démarrée"
}

# Arrête la collecte de métriques
metrics_stop() {
    METRICS_END_TIME=$(date +%s)
    log_debug "Collecte de métriques arrêtée"
}

# Enregistre le traitement d'un dépôt
metrics_record_repo() {
    local repo_name="$1"
    local action="$2"  # cloned, updated, failed
    local size="$3"   # taille en MB
    local duration="$4"  # durée en secondes
    
    case "$action" in
        cloned)
            METRICS_CLONED=$((METRICS_CLONED + 1))
            ;;
        updated)
            METRICS_UPDATED=$((METRICS_UPDATED + 1))
            ;;
        failed)
            METRICS_FAILED=$((METRICS_FAILED + 1))
            ;;
    esac
    
    METRICS_TOTAL_SIZE=$((METRICS_TOTAL_SIZE + size))
    METRICS_REPO_TIMES+=("$repo_name|$action|$duration|$size")
    
    log_debug "Métrique enregistrée: $repo_name ($action, ${size}MB, ${duration}s)"
}

# Calcule les métriques dérivées
metrics_calculate() {
    local total_processed=$((METRICS_CLONED + METRICS_UPDATED + METRICS_FAILED))
    local success_rate=0
    
    if [ "$total_processed" -gt 0 ]; then
        success_rate=$(( (METRICS_CLONED + METRICS_UPDATED) * 100 / total_processed ))
    fi
    
    local total_duration=0
    if [ -n "$METRICS_START_TIME" ] && [ -n "$METRICS_END_TIME" ]; then
        total_duration=$((METRICS_END_TIME - METRICS_START_TIME))
    fi
    
    local avg_time_per_repo=0
    if [ "$total_processed" -gt 0 ]; then
        avg_time_per_repo=$((total_duration / total_processed))
    fi
    
    echo "$total_processed|$success_rate|$total_duration|$avg_time_per_repo"
}

# Exporte les métriques au format JSON
metrics_export_json() {
    local output_file="$1"
    
    local calculated
    calculated=$(metrics_calculate)
    IFS='|' read -r total_processed success_rate total_duration avg_time_per_repo <<< "$calculated"
    
    local metrics_json
    metrics_json=$(cat <<EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "duration_seconds": $total_duration,
  "total_repos": $METRICS_TOTAL_REPOS,
  "processed": $total_processed,
  "cloned": $METRICS_CLONED,
  "updated": $METRICS_UPDATED,
  "failed": $METRICS_FAILED,
  "success_rate": $success_rate,
  "total_size_mb": $METRICS_TOTAL_SIZE,
  "avg_time_per_repo_seconds": $avg_time_per_repo,
  "repos": [
EOF
)
    
    # Ajouter les détails des dépôts
    local first=true
    for repo_info in "${METRICS_REPO_TIMES[@]}"; do
        IFS='|' read -r repo_name action duration size <<< "$repo_info"
        
        if [ "$first" = true ]; then
            first=false
        else
            metrics_json+=","
        fi
        
        metrics_json+="
    {
      \"name\": \"$repo_name\",
      \"action\": \"$action\",
      \"duration_seconds\": $duration,
      \"size_mb\": $size
    }"
    done
    
    metrics_json+="
  ]
}"
    
    if [ -n "$output_file" ]; then
        echo "$metrics_json" > "$output_file"
        log_success "Métriques exportées vers: $output_file"
    else
        echo "$metrics_json"
    fi
}

# Exporte les métriques au format CSV
metrics_export_csv() {
    local output_file="$1"
    
    local calculated
    calculated=$(metrics_calculate)
    IFS='|' read -r total_processed success_rate total_duration avg_time_per_repo <<< "$calculated"
    
    local csv_header csv_row
    csv_header="timestamp,duration_seconds,total_repos,processed,cloned,updated,failed"
    csv_header+=",success_rate,total_size_mb,avg_time_per_repo_seconds"
    
    csv_row="$(date -u +%Y-%m-%dT%H:%M:%SZ),$total_duration,$METRICS_TOTAL_REPOS"
    csv_row+=",$total_processed,$METRICS_CLONED,$METRICS_UPDATED,$METRICS_FAILED"
    csv_row+=",$success_rate,$METRICS_TOTAL_SIZE,$avg_time_per_repo"
    
    local csv_data="$csv_header
$csv_row"
    
    # Ajouter les détails des dépôts
    csv_data+="
repo_name,action,duration_seconds,size_mb"
    
    for repo_info in "${METRICS_REPO_TIMES[@]}"; do
        IFS='|' read -r repo_name action duration size <<< "$repo_info"
        csv_data+="
$repo_name,$action,$duration,$size"
    done
    
    if [ -n "$output_file" ]; then
        echo "$csv_data" > "$output_file"
        log_success "Métriques exportées vers: $output_file"
    else
        echo "$csv_data"
    fi
}

# Exporte les métriques au format HTML
metrics_export_html() {
    local output_file="$1"
    
    local calculated
    calculated=$(metrics_calculate)
    IFS='|' read -r total_processed success_rate total_duration avg_time_per_repo <<< "$calculated"
    
    # Calculer la vitesse moyenne
    local avg_speed
    if [ "$total_duration" -gt 0 ]; then
        avg_speed=$(echo "scale=2; $total_processed / $total_duration" | bc -l)
    else
        avg_speed="0.00"
    fi
    
    # Calculer la taille moyenne par repo
    # Calcul de la taille moyenne par repo (pour affichage optionnel)
    # local avg_size
    # if [ "$total_processed" -gt 0 ]; then
    #     avg_size=$(echo "scale=2; $METRICS_TOTAL_SIZE / $total_processed" | bc -l)
    # else
    #     avg_size="0.00"
    # fi
    
    local html_content
    html_content=$(cat <<EOF
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Git Mirror - Rappo rt de Métriques</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 20px;
            background: #f5f5f5;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        h1 {
            color: #333;
            border-bottom: 3px solid #007bff;
            padding-bottom: 10px;
        }
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin: 30px 0;
        }
        .stat-card {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 6px;
            border-left: 4px solid #007bff;
        }
        .stat-card.success {
            border-left-color: #28a745;
        }
        .stat-card.warning {
            border-left-color: #ffc107;
        }
        .stat-card.error {
            border-left-color: #dc3545;
        }
        .stat-label {
            font-size: 0.9em;
            color: #666;
            margin-bottom: 5px;
        }
        .stat-value {
            font-size: 2em;
            font-weight: bold;
            color: #333;
        }
        .stat-value.success { color: #28a745; }
        .stat-value.warning { color: #ffc107; }
        .stat-value.error { color: #dc3545; }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }
        th, td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background: #007bff;
            color: white;
            font-weight: bold;
        }
        tr:hover {
            background: #f8f9fa;
        }
        .badge {
            display: inline-block;
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 0.85em;
            font-weight: bold;
        }
        .badge.cloned {
            background: #d4edda;
            color: #155724;
        }
        .badge.updated {
            background: #cce5ff;
            color: #004085;
        }
        .badge.failed {
            background: #f8d7da;
            color: #721c24;
        }
        .timestamp {
            color: #666;
            font-size: 0.9em;
            margin-top: 20px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>📊 Git Mirror - Rapport de Métriques</h1>
        
        <div class="timestamp">
            Généré le: $(date '+%d/%m/%Y à %H:%M:%S')
        </div>
        
        <div class="stats-grid">
            <div class="stat-card success">
                <div class="stat-label">Dépôts Total</div>
                <div class="stat-value">$METRICS_TOTAL_REPOS</div>
            </div>
            
            <div class="stat-card success">
                <div class="stat-label">Clonés</div>
                <div class="stat-value success">$METRICS_CLONED</div>
            </div>
            
            <div class="stat-card">
                <div class="stat-label">Mis à Jour</div>
                <div class="stat-value">$METRICS_UPDATED</div>
            </div>
            
            <div class="stat-card error">
                <div class="stat-label">Échecs</div>
                <div class="stat-value error">$METRICS_FAILED</div>
            </div>
            
            <div class="stat-card success">
                <div class="stat-label">Taux de Succès</div>
                <div class="stat-value success">${success_rate}%</div>
            </div>
            
            <div class="stat-card">
                <div class="stat-label">Durée Totale</div>
                <div class="stat-value">${total_duration}s</div>
            </div>
            
            <div class="stat-card">
                <div class="stat-label">Vitesse Moyenne</div>
                <div class="stat-value">${avg_speed} repos/s</div>
            </div>
            
            <div class="stat-card">
                <div class="stat-label">Taille Totale</div>
                <div class="stat-value">${METRICS_TOTAL_SIZE} MB</div>
            </div>
        </div>
        
        <h2>📋 Détails des Dépôts</h2>
        <table>
            <thead>
                <tr>
                    <th>Dépôt</th>
                    <th>Action</th>
                    <th>Durée (s)</th>
                    <th>Taille (MB)</th>
                </tr>
            </thead>
            <tbody>
EOF
)
    
    # Ajouter les lignes de dépôts
    for repo_info in "${METRICS_REPO_TIMES[@]}"; do
        IFS='|' read -r repo_name action duration size <<< "$repo_info"
        
        # Déterminer le badge selon l'action
        local badge_class
        case "$action" in
            cloned) badge_class="cloned" ;;
            updated) badge_class="updated" ;;
            failed) badge_class="failed" ;;
            *) badge_class="" ;;
        esac
        
        html_content+="<tr><td>$repo_name</td><td><span class=\"badge $badge_class\">$action</span></td><td>$duration</td><td>$size</td></tr>"
    done
    
    html_content+="
            </tbody>
        </table>
    </div>
</body>
</html>
"
    
    if [ -n "$output_file" ]; then
        echo "$html_content" > "$output_file"
        log_success "Métriques exportées en HTML vers: $output_file"
    else
        echo "$html_content"
    fi
}

# Affiche un résumé des métriques
metrics_show_summary() {
    local calculated
    calculated=$(metrics_calculate)
    IFS='|' read -r total_processed success_rate total_duration avg_time_per_repo <<< "$calculated"
    
    log_info "=== Résumé des Métriques ==="
    log_info "Durée totale: ${total_duration}s"
    log_info "Total dépôts: $METRICS_TOTAL_REPOS"
    log_info "Traités: $total_processed"
    log_info "Clonés: $METRICS_CLONED"
    log_info "Mis à jour: $METRICS_UPDATED"
    log_info "Échecs: $METRICS_FAILED"
    log_info "Taux de succès: ${success_rate}%"
    log_info "Taille totale: ${METRICS_TOTAL_SIZE}MB"
    log_info "Temps moyen par dépôt: ${avg_time_per_repo}s"
    log_info "=========================="
}

# Exporte les métriques selon le format configuré
metrics_export() {
    local output_file="$1"
    
    if [ "$METRICS_ENABLED" != "true" ]; then
        log_debug "Métriques désactivées"
    return 0
    fi
    
    if [ -z "$output_file" ]; then
        output_file="$METRICS_FILE"
    fi
    
    if [ -z "$output_file" ]; then
        log_warning "Aucun fichier de sortie spécifié pour les métriques"
        return 1
    fi
    
    case "$METRICS_FORMAT" in
        json)
            metrics_export_json "$output_file"
            ;;
        csv)
            metrics_export_csv "$output_file"
            ;;
        html)
            metrics_export_html "$output_file"
            ;;
        *)
            log_error "Format de métriques non supporté: $METRICS_FORMAT"
            return 1
            ;;
    esac
    
    return 0
}

# Nettoie les métriques
metrics_cleanup() {
    METRICS_START_TIME=""
    METRICS_END_TIME=""
    METRICS_TOTAL_REPOS=0
    METRICS_CLONED=0
    METRICS_UPDATED=0
    METRICS_FAILED=0
    METRICS_TOTAL_SIZE=0
    METRICS_REPO_TIMES=()
    
    log_debug "Métriques nettoyées"
}

# Fonction principale d'initialisation du module de métriques
metrics_setup() {
    if ! metrics_init; then
        log_error "Échec de l'initialisation du module de métriques"
        return 1
    fi
    
    if [ "$METRICS_ENABLED" = "true" ]; then
        log_success "Module de métriques initialisé avec succès"
        log_info "Format d'export: $METRICS_FORMAT"
        if [ -n "$METRICS_FILE" ]; then
            log_info "Fichier de sortie: $METRICS_FILE"
        fi
    else
        log_debug "Module de métriques désactivé"
    fi
    
    return 0
}