#!/usr/bin/env bats
# test_filters.bats - Tests unitaires pour le module de filtrage

load 'test_helper.bash'

@test "filters_init initializes filter module" {
    export FILTER_ENABLED=true
    export EXCLUDE_PATTERNS="test-*,*-backup"
    export INCLUDE_PATTERNS="important-*"
    
    run filters_init
    
    [ "$status" -eq 0 ]
}

@test "filters_should_process returns true when filtering disabled" {
    export FILTER_ENABLED=false
    
    run filters_should_process "test-repo" "user/test-repo"
    
    [ "$status" -eq 0 ]
}

@test "filters_should_process excludes repos matching exclude patterns" {
    export FILTER_ENABLED=true
    export EXCLUDE_PATTERNS="test-*"
    
    # Initialize filters
    filters_init
    
    run filters_should_process "test-repo" "user/test-repo"
    
    [ "$status" -eq 1 ]
}

@test "filters_should_process includes repos matching include patterns" {
    export FILTER_ENABLED=true
    export INCLUDE_PATTERNS="important-*"
    
    # Initialize filters
    filters_init
    
    run filters_should_process "important-repo" "user/important-repo"
    
    [ "$status" -eq 0 ]
}

@test "filters_should_process excludes repos not matching include patterns" {
    export FILTER_ENABLED=true
    export INCLUDE_PATTERNS="important-*"
    
    # Initialize filters
    filters_init
    
    run filters_should_process "other-repo" "user/other-repo"
    
    [ "$status" -eq 1 ]
}

@test "filters_match_pattern matches exact pattern" {
    run filters_match_pattern "test-repo" "test-repo"
    
    [ "$status" -eq 0 ]
}

@test "filters_match_pattern matches glob pattern" {
    run filters_match_pattern "test-repo" "test-*"
    
    [ "$status" -eq 0 ]
}

@test "filters_match_pattern matches regex pattern" {
    run filters_match_pattern "test-repo" "^test-.*$"
    
    [ "$status" -eq 0 ]
}

@test "filters_match_pattern does not match non-matching pattern" {
    run filters_match_pattern "other-repo" "test-*"
    
    [ "$status" -eq 1 ]
}

@test "filters_filter_repos filters repository list" {
    export FILTER_ENABLED=true
    export EXCLUDE_PATTERNS="test-*"
    
    # Initialize filters
    filters_init
    
    local repos_json='[{"name": "test-repo", "full_name": "user/test-repo"}, {"name": "real-repo", "full_name": "user/real-repo"}]'
    
    # Capturer stdout uniquement (ignorer stderr avec les logs)
    local result
    result=$(filters_filter_repos "$repos_json" 2>/dev/null)
    
    [ "$?" -eq 0 ]
    
    # Vérifier que seulement real-repo est présent
    local repo_count
    repo_count=$(echo "$result" | jq '. | length')
    [ "$repo_count" -eq 1 ]
    
    local repo_name
    repo_name=$(echo "$result" | jq -r '.[0].name')
    [ "$repo_name" = "real-repo" ]
}

@test "filters_show_summary displays filter configuration" {
    export FILTER_ENABLED=true
    export EXCLUDE_PATTERNS="test-*"
    export INCLUDE_PATTERNS="important-*"
    
    # Initialize filters
    filters_init
    
    run filters_show_summary
    
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Patterns d'exclusion" ]]
    [[ "$output" =~ "Patterns d'inclusion" ]]
}

@test "filters_validate_patterns validates correct patterns" {
    export FILTER_ENABLED=true
    export EXCLUDE_PATTERNS="test-*,*-backup"
    export INCLUDE_PATTERNS="important-*"
    
    # Initialize filters
    filters_init
    
    run filters_validate_patterns
    
    [ "$status" -eq 0 ]
}

@test "filters_validate_pattern validates individual pattern" {
    run filters_validate_pattern "test-*"
    
    [ "$status" -eq 0 ]
}

@test "filters_validate_pattern rejects empty pattern" {
    run filters_validate_pattern ""
    
    [ "$status" -eq 1 ]
}

@test "filters_setup initializes filter module" {
    export FILTER_ENABLED=true
    export EXCLUDE_PATTERNS="test-*"
    
    run filters_setup
    
    [ "$status" -eq 0 ]
}
