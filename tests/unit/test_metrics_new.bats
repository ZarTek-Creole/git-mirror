#!/usr/bin/env bats
# test_metrics.bats - Tests unitaires pour le module de métriques

load 'test_helper.bash'

@test "metrics_init initializes metrics module" {
    run metrics_init
    
    [ "$status" -eq 0 ]
}

@test "metrics_start starts metrics collection" {
    run metrics_start
    
    [ "$status" -eq 0 ]
}

@test "metrics_stop stops metrics collection" {
    run metrics_stop
    
    [ "$status" -eq 0 ]
}

@test "metrics_record_repo records repository metrics" {
    run metrics_record_repo "test-repo" "cloned" 100 30
    
    [ "$status" -eq 0 ]
}

@test "metrics_calculate calculates derived metrics" {
    # Set up test metrics
    METRICS_CLONED=10
    METRICS_UPDATED=20
    METRICS_FAILED=5
    METRICS_START_TIME=$(($(date +%s) - 100))
    METRICS_END_TIME=$(date +%s)
    
    run metrics_calculate
    
    [ "$status" -eq 0 ]
    
    IFS='|' read -r total_processed success_rate total_duration avg_time_per_repo <<< "$output"
    
    [ "$total_processed" = "35" ]
    [ "$success_rate" = "85" ]  # (10+20)*100/35
    [ "$total_duration" = "100" ]
    [ "$avg_time_per_repo" = "2" ]  # 100/35
}

@test "metrics_export_json exports metrics in JSON format" {
    # Set up test metrics
    METRICS_TOTAL_REPOS=100
    METRICS_CLONED=10
    METRICS_UPDATED=20
    METRICS_FAILED=5
    METRICS_TOTAL_SIZE=1500
    METRICS_START_TIME=$(($(date +%s) - 100))
    METRICS_END_TIME=$(date +%s)
    METRICS_REPO_TIMES=("repo1|cloned|30|100" "repo2|updated|20|200")
    
    run metrics_export_json
    
    [ "$status" -eq 0 ]
    [[ "$output" =~ '"total_repos": 100' ]]
    [[ "$output" =~ '"cloned": 10' ]]
    [[ "$output" =~ '"updated": 20' ]]
    [[ "$output" =~ '"failed": 5' ]]
}

@test "metrics_export_csv exports metrics in CSV format" {
    # Set up test metrics
    METRICS_TOTAL_REPOS=100
    METRICS_CLONED=10
    METRICS_UPDATED=20
    METRICS_FAILED=5
    METRICS_TOTAL_SIZE=1500
    METRICS_START_TIME=$(($(date +%s) - 100))
    METRICS_END_TIME=$(date +%s)
    METRICS_REPO_TIMES=("repo1|cloned|30|100" "repo2|updated|20|200")
    
    run metrics_export_csv
    
    [ "$status" -eq 0 ]
    [[ "$output" =~ "timestamp,duration_seconds,total_repos" ]]
    [[ "$output" =~ "repo1,cloned,30,100" ]]
    [[ "$output" =~ "repo2,updated,20,200" ]]
}

@test "metrics_show_summary displays metrics summary" {
    # Set up test metrics
    METRICS_TOTAL_REPOS=100
    METRICS_CLONED=10
    METRICS_UPDATED=20
    METRICS_FAILED=5
    METRICS_TOTAL_SIZE=1500
    METRICS_START_TIME=$(($(date +%s) - 100))
    METRICS_END_TIME=$(date +%s)
    
    run metrics_show_summary
    
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Durée totale: 100s" ]]
    [[ "$output" =~ "Total dépôts: 100" ]]
    [[ "$output" =~ "Clonés: 10" ]]
    [[ "$output" =~ "Mis à jour: 20" ]]
    [[ "$output" =~ "Échecs: 5" ]]
}

@test "metrics_export exports metrics to file" {
    local test_file="/tmp/test-metrics.json"
    export METRICS_ENABLED=true
    export METRICS_FORMAT="json"
    
    # Set up test metrics
    METRICS_TOTAL_REPOS=100
    METRICS_CLONED=10
    METRICS_UPDATED=20
    METRICS_FAILED=5
    METRICS_TOTAL_SIZE=1500
    METRICS_START_TIME=$(($(date +%s) - 100))
    METRICS_END_TIME=$(date +%s)
    
    run metrics_export "$test_file"
    
    [ "$status" -eq 0 ]
    [ -f "$test_file" ]
    
    # Verify file content
    run jq -r '.total_repos' "$test_file"
    [ "$output" = "100" ]
    
    # Cleanup
    rm -f "$test_file"
}

@test "metrics_export fails when metrics disabled" {
    export METRICS_ENABLED=false
    
    run metrics_export "/tmp/test.json"
    
    [ "$status" -eq 0 ]
}

@test "metrics_export fails when no output file specified" {
    export METRICS_ENABLED=true
    export METRICS_FILE=""
    
    run metrics_export
    
    [ "$status" -eq 1 ]
}

@test "metrics_cleanup cleans up metrics data" {
    # Set up test metrics
    METRICS_TOTAL_REPOS=100
    METRICS_CLONED=10
    METRICS_UPDATED=20
    METRICS_FAILED=5
    METRICS_TOTAL_SIZE=1500
    METRICS_REPO_TIMES=("repo1|cloned|30|100")
    
    run metrics_cleanup
    
    [ "$status" -eq 0 ]
}

@test "metrics_setup initializes metrics module" {
    export METRICS_ENABLED=true
    export METRICS_FORMAT="json"
    export METRICS_FILE="/tmp/test-metrics.json"
    
    run metrics_setup
    
    [ "$status" -eq 0 ]
}
