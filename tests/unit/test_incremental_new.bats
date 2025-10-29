#!/usr/bin/env bats
# test_incremental.bats - Tests unitaires pour le module incrémental

load 'test_helper.bash'

@test "incremental_init creates cache directory" {
    local test_cache_dir="/tmp/test-incremental-cache"
    export INCREMENTAL_CACHE_DIR="$test_cache_dir"
    
    run incremental_init
    
    [ "$status" -eq 0 ]
    [ -d "$test_cache_dir" ]
    
    # Cleanup
    rm -rf "$test_cache_dir"
}

@test "incremental_get_last_sync returns empty when no sync file" {
    local test_sync_file="/tmp/non-existent-sync"
    export INCREMENTAL_LAST_SYNC_FILE="$test_sync_file"
    
    run incremental_get_last_sync
    
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "incremental_get_last_sync returns last sync timestamp" {
    local test_sync_file="/tmp/test-sync"
    export INCREMENTAL_LAST_SYNC_FILE="$test_sync_file"
    
    echo "2025-10-25T16:00:00Z" > "$test_sync_file"
    
    run incremental_get_last_sync
    
    [ "$status" -eq 0 ]
    [ "$output" = "2025-10-25T16:00:00Z" ]
    
    # Cleanup
    rm -f "$test_sync_file"
}

@test "incremental_update_timestamp updates sync timestamp" {
    local test_sync_file="/tmp/test-sync"
    export INCREMENTAL_LAST_SYNC_FILE="$test_sync_file"
    
    run incremental_update_timestamp
    
    [ "$status" -eq 0 ]
    [ -f "$test_sync_file" ]
    
    # Verify timestamp format
    run cat "$test_sync_file"
    [[ "$output" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]
    
    # Cleanup
    rm -f "$test_sync_file"
}

@test "incremental_filter_updated returns all repos when incremental disabled" {
    export INCREMENTAL_ENABLED=false
    
    local repos_json='[{"name": "repo1", "pushed_at": "2025-10-25T15:00:00Z"}, {"name": "repo2", "pushed_at": "2025-10-25T17:00:00Z"}]'
    
    run incremental_filter_updated "$repos_json" "2025-10-25T16:00:00Z"
    
    [ "$status" -eq 0 ]
    [ "$output" = "$repos_json" ]
}

@test "incremental_filter_updated returns all repos when no last sync" {
    export INCREMENTAL_ENABLED=true
    
    local repos_json='[{"name": "repo1", "pushed_at": "2025-10-25T15:00:00Z"}, {"name": "repo2", "pushed_at": "2025-10-25T17:00:00Z"}]'
    
    run incremental_filter_updated "$repos_json" ""
    
    [ "$status" -eq 0 ]
    [ "$output" = "$repos_json" ]
}

@test "incremental_filter_updated filters repos by pushed_at" {
    export INCREMENTAL_ENABLED=true
    
    local repos_json='[{"name": "repo1", "pushed_at": "2025-10-25T15:00:00Z"}, {"name": "repo2", "pushed_at": "2025-10-25T17:00:00Z"}]'
    
    run incremental_filter_updated "$repos_json" "2025-10-25T16:00:00Z"
    
    [ "$status" -eq 0 ]
    
    # Should only contain repo2 (pushed after last sync)
    run echo "$output" | jq -r '.[0].name'
    [ "$output" = "repo2" ]
}

@test "incremental_is_repo_updated returns true when incremental disabled" {
    export INCREMENTAL_ENABLED=false
    
    run incremental_is_repo_updated "repo1" "2025-10-25T17:00:00Z" "2025-10-25T16:00:00Z"
    
    [ "$status" -eq 0 ]
}

@test "incremental_is_repo_updated returns true when repo updated after last sync" {
    export INCREMENTAL_ENABLED=true
    
    run incremental_is_repo_updated "repo1" "2025-10-25T17:00:00Z" "2025-10-25T16:00:00Z"
    
    [ "$status" -eq 0 ]
}

@test "incremental_is_repo_updated returns false when repo not updated since last sync" {
    export INCREMENTAL_ENABLED=true
    
    run incremental_is_repo_updated "repo1" "2025-10-25T15:00:00Z" "2025-10-25T16:00:00Z"
    
    [ "$status" -eq 1 ]
}

@test "incremental_is_repo_updated returns true when date parsing fails" {
    export INCREMENTAL_ENABLED=true
    
    run incremental_is_repo_updated "repo1" "invalid-date" "2025-10-25T16:00:00Z"
    
    [ "$status" -eq 0 ]
}

@test "incremental_get_stats displays incremental statistics" {
    export INCREMENTAL_ENABLED=true
    
    run incremental_get_stats 100 50 "2025-10-25T16:00:00Z"
    
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Mode incrémental" ]]
    [[ "$output" =~ "Dernière synchronisation: 2025-10-25T16:00:00Z" ]]
    [[ "$output" =~ "Total dépôts: 100" ]]
    [[ "$output" =~ "Dépôts traités: 50" ]]
    [[ "$output" =~ "Dépôts ignorés: 50" ]]
}

@test "incremental_get_stats shows disabled message when incremental disabled" {
    export INCREMENTAL_ENABLED=false
    
    run incremental_get_stats 100 50 "2025-10-25T16:00:00Z"
    
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Mode incrémental désactivé" ]]
}

@test "incremental_cleanup removes cache directory" {
    local test_cache_dir="/tmp/test-incremental-cache"
    export INCREMENTAL_CACHE_DIR="$test_cache_dir"
    
    mkdir -p "$test_cache_dir"
    echo "test" > "$test_cache_dir/test-file"
    
    run incremental_cleanup
    
    [ "$status" -eq 0 ]
    [ ! -d "$test_cache_dir" ]
}

@test "incremental_show_summary displays incremental configuration" {
    export INCREMENTAL_ENABLED=true
    export INCREMENTAL_CACHE_DIR="/tmp/test-cache"
    
    # Mock last sync
    incremental_get_last_sync() {
        echo "2025-10-25T16:00:00Z"
    }
    
    run incremental_show_summary
    
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Mode incrémental: Activé" ]]
    [[ "$output" =~ "Dernière synchronisation: 2025-10-25T16:00:00Z" ]]
    [[ "$output" =~ "Cache: /tmp/test-cache" ]]
}

@test "incremental_show_summary shows disabled message when incremental disabled" {
    export INCREMENTAL_ENABLED=false
    
    run incremental_show_summary
    
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Mode incrémental désactivé" ]]
}

@test "incremental_setup initializes incremental module" {
    export INCREMENTAL_ENABLED=true
    export INCREMENTAL_CACHE_DIR="/tmp/test-incremental-cache"
    
    run incremental_setup
    
    [ "$status" -eq 0 ]
    [ -d "/tmp/test-incremental-cache" ]
    
    # Cleanup
    rm -rf "/tmp/test-incremental-cache"
}
