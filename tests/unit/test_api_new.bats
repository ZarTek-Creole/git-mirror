#!/usr/bin/env bats
# test_api.bats - Tests unitaires pour le module API GitHub

load 'test_helper.bash'

@test "api_init creates cache directory" {
    local test_cache_dir="/tmp/test-api-cache"
    export API_CACHE_DIR="$test_cache_dir"
    
    run api_init
    
    [ "$status" -eq 0 ]
    [ -d "$test_cache_dir" ]
    
    # Cleanup
    rm -rf "$test_cache_dir"
}

@test "api_cache_key generates valid cache key" {
    run api_cache_key "https://api.github.com/user/repos"
    
    [ "$status" -eq 0 ]
    [ -n "$output" ]
    [[ "$output" =~ ^[a-zA-Z0-9_.]+$ ]]
}

@test "api_cache_valid returns true for valid cache" {
    local test_cache_file="/tmp/test-cache.json"
    echo '{"test": "data"}' > "$test_cache_file"
    
    run api_cache_valid "$test_cache_file" 3600
    
    [ "$status" -eq 0 ]
    
    # Cleanup
    rm -f "$test_cache_file"
}

@test "api_cache_valid returns false for expired cache" {
    local test_cache_file="/tmp/test-cache-expired.json"
    echo '{"test": "data"}' > "$test_cache_file"
    
    # Make file old
    touch -t 202001010000 "$test_cache_file"
    
    run api_cache_valid "$test_cache_file" 3600
    
    [ "$status" -eq 1 ]
    
    # Cleanup
    rm -f "$test_cache_file"
}

@test "api_cache_valid returns false for non-existent file" {
    run api_cache_valid "/tmp/non-existent.json" 3600
    
    [ "$status" -eq 1 ]
}

@test "api_check_rate_limit handles valid response" {
    export GITHUB_AUTH_METHOD="public"
    
    # Mock successful API call
    curl() {
        echo '{"rate": {"remaining": 5000, "limit": 5000, "reset": 1640995200}}'
        return 0
    }
    
    run api_check_rate_limit
    
    [ "$status" -eq 0 ]
}

@test "api_check_rate_limit handles rate limit exceeded" {
    export GITHUB_AUTH_METHOD="public"
    
    # Mock rate limit exceeded
    curl() {
        echo '{"rate": {"remaining": 0, "limit": 5000, "reset": 1640995200}}'
        return 0
    }
    
    run api_check_rate_limit
    
    [ "$status" -eq 0 ]
}

@test "api_wait_rate_limit waits when rate limit exceeded" {
    export GITHUB_AUTH_METHOD="public"
    
    # Mock rate limit exceeded with future reset time
    curl() {
        local future_time=$(($(date +%s) + 10))
        echo "{\"rate\": {\"remaining\": 0, \"limit\": 5000, \"reset\": $future_time}}"
        return 0
    }
    
    run api_wait_rate_limit
    
    [ "$status" -eq 0 ]
}

@test "api_fetch_with_cache uses cache when valid" {
    local test_cache_dir="/tmp/test-api-cache"
    export API_CACHE_DIR="$test_cache_dir"
    export API_CACHE_TTL=3600
    export GITHUB_AUTH_METHOD="public"
    
    mkdir -p "$test_cache_dir"
    
    local test_url="https://api.github.com/test"
    local cache_key
    cache_key=$(api_cache_key "$test_url")
    local cache_file="$test_cache_dir/$cache_key.json"
    
    echo '{"cached": "data"}' > "$cache_file"
    
    run api_fetch_with_cache "$test_url"
    
    [ "$status" -eq 0 ]
    [ "$output" = '{"cached": "data"}' ]
    
    # Cleanup
    rm -rf "$test_cache_dir"
}

@test "api_fetch_with_cache makes API call when cache invalid" {
    local test_cache_dir="/tmp/test-api-cache"
    export API_CACHE_DIR="$test_cache_dir"
    export API_CACHE_TTL=3600
    export GITHUB_AUTH_METHOD="public"
    
    mkdir -p "$test_cache_dir"
    
    local test_url="https://api.github.com/test"
    
    # Mock successful API call with HTTP code
    curl() {
        echo '{"api": "data"}200'
        return 0
    }
    
    # Mock rate limit check to always return true
    api_check_rate_limit() {
        return 0
    }
    
    run api_fetch_with_cache "$test_url"
    
    [ "$status" -eq 0 ]
    [ "$output" = '{"api": "data"}' ]
    
    # Cleanup
    rm -rf "$test_cache_dir"
}

@test "api_get_total_repos returns cached value when available" {
    local test_cache_dir="/tmp/test-api-cache"
    export API_CACHE_DIR="$test_cache_dir"
    export API_CACHE_TTL=3600
    export GITHUB_AUTH_METHOD="public"
    
    mkdir -p "$test_cache_dir"
    
    local cache_key
    cache_key=$(api_cache_key "total_users_testuser")
    local cache_file="$test_cache_dir/${cache_key}.json"
    
    echo "150" > "$cache_file"
    
    run api_get_total_repos "users" "testuser"
    
    [ "$status" -eq 0 ]
    [ "$output" = "150" ]
    
    # Cleanup
    rm -rf "$test_cache_dir"
}

@test "api_get_total_repos returns default when API fails" {
    export GITHUB_AUTH_METHOD="public"
    
    # Mock failed API call
    api_fetch_with_cache() {
        return 1
    }
    
    run api_get_total_repos "users" "testuser"
    
    [ "$status" -eq 0 ]
    # Extraire la dernière ligne qui contient "100"
    local last_line=$(echo "$output" | tail -n1)
    [ "$last_line" = "100" ]
}

@test "api_setup initializes API module" {
    local test_cache_dir="/tmp/test-api-cache"
    export API_CACHE_DIR="$test_cache_dir"
    
    run api_setup
    
    [ "$status" -eq 0 ]
    [ -d "$test_cache_dir" ]
    
    # Cleanup
    rm -rf "$test_cache_dir"
}
