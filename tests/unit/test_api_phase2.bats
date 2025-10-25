#!/usr/bin/env bats
# test_api_phase2.bats - Tests unitaires Phase 2 pour le module API GitHub

load 'test_helper.bash'

@test "api_fetch_with_cache handles HTTP 200 response" {
    local test_cache_dir="/tmp/test-api-cache"
    export API_CACHE_DIR="$test_cache_dir"
    export API_CACHE_TTL=3600
    export GITHUB_AUTH_METHOD="public"
    
    mkdir -p "$test_cache_dir"
    
    # Mock successful HTTP 200 response
    curl() {
        echo '{"data": "test"}200'
    
    # Mock rate limit check to always return true
    api_check_rate_limit() {
        return 0
    }
        return 0
    }
    
    # Mock rate limit check to always return true
    api_check_rate_limit() {
        return 0
    }
    
    run api_fetch_with_cache "https://api.github.com/test"
    
    [ "$status" -eq 0 ]
    [ "$output" = '{"data": "test"}' ]
    
    # Cleanup
    rm -rf "$test_cache_dir"
}

@test "api_fetch_with_cache handles HTTP 403 response" {
    local test_cache_dir="/tmp/test-api-cache"
    export API_CACHE_DIR="$test_cache_dir"
    export API_CACHE_TTL=3600
    export GITHUB_AUTH_METHOD="public"
    
    mkdir -p "$test_cache_dir"
    
    # Mock HTTP 403 response
    curl() {
        echo '{"message": "API rate limit exceeded"}403'
    
    # Mock rate limit check to always return true
    api_check_rate_limit() {
        return 0
    }
        return 0
    }
    
    # Mock rate limit check to always return true
    api_check_rate_limit() {
        return 0
    }
    
    run api_fetch_with_cache "https://api.github.com/test"
    
    [ "$status" -eq 1 ]
    
    # Cleanup
    rm -rf "$test_cache_dir"
}

@test "api_fetch_with_cache handles HTTP 404 response" {
    local test_cache_dir="/tmp/test-api-cache"
    export API_CACHE_DIR="$test_cache_dir"
    export API_CACHE_TTL=3600
    export GITHUB_AUTH_METHOD="public"
    
    mkdir -p "$test_cache_dir"
    
    # Mock HTTP 404 response
    curl() {
        echo '{"message": "Not Found"}404'
    
    # Mock rate limit check to always return true
    api_check_rate_limit() {
        return 0
    }
        return 0
    }
    
    run api_fetch_with_cache "https://api.github.com/test"
    
    [ "$status" -eq 1 ]
    
    # Cleanup
    rm -rf "$test_cache_dir"
}

@test "api_fetch_with_cache handles HTTP 429 response" {
    local test_cache_dir="/tmp/test-api-cache"
    export API_CACHE_DIR="$test_cache_dir"
    export API_CACHE_TTL=3600
    export GITHUB_AUTH_METHOD="public"
    
    mkdir -p "$test_cache_dir"
    
    # Mock HTTP 429 response
    curl() {
        echo '{"message": "Too Many Requests"}429'
    
    # Mock rate limit check to always return true
    api_check_rate_limit() {
        return 0
    }
        return 0
    }
    
    run api_fetch_with_cache "https://api.github.com/test"
    
    [ "$status" -eq 1 ]
    
    # Cleanup
    rm -rf "$test_cache_dir"
}

@test "api_fetch_with_cache handles empty response" {
    local test_cache_dir="/tmp/test-api-cache"
    export API_CACHE_DIR="$test_cache_dir"
    export API_CACHE_TTL=3600
    export GITHUB_AUTH_METHOD="public"
    
    mkdir -p "$test_cache_dir"
    
    # Mock empty response
    curl() {
        echo '200'
        return 0
    }
    
    # Mock rate limit check to always return true
    api_check_rate_limit() {
        return 0
    }
    
    run api_fetch_with_cache "https://api.github.com/test"
    
    [ "$status" -eq 1 ]
    
    # Cleanup
    rm -rf "$test_cache_dir"
}

@test "api_fetch_with_cache handles invalid JSON response" {
    local test_cache_dir="/tmp/test-api-cache"
    export API_CACHE_DIR="$test_cache_dir"
    export API_CACHE_TTL=3600
    export GITHUB_AUTH_METHOD="public"
    
    mkdir -p "$test_cache_dir"
    
    # Mock invalid JSON response
    curl() {
        echo 'invalid json200'
        return 0
    }
    
    # Mock rate limit check to always return true
    api_check_rate_limit() {
        return 0
    }
    
    run api_fetch_with_cache "https://api.github.com/test"
    
    [ "$status" -eq 1 ]
    
    # Cleanup
    rm -rf "$test_cache_dir"
}

@test "api_fetch_with_cache handles JSON error message" {
    local test_cache_dir="/tmp/test-api-cache"
    export API_CACHE_DIR="$test_cache_dir"
    export API_CACHE_TTL=3600
    export GITHUB_AUTH_METHOD="public"
    
    mkdir -p "$test_cache_dir"
    
    # Mock JSON error response
    curl() {
        echo '{"message": "API rate limit exceeded"}200'
    
    # Mock rate limit check to always return true
    api_check_rate_limit() {
        return 0
    }
        return 0
    }
    
    run api_fetch_with_cache "https://api.github.com/test"
    
    [ "$status" -eq 1 ]
    
    # Cleanup
    rm -rf "$test_cache_dir"
}

@test "api_fetch_with_cache handles rate limit error message" {
    local test_cache_dir="/tmp/test-api-cache"
    export API_CACHE_DIR="$test_cache_dir"
    export API_CACHE_TTL=3600
    export GITHUB_AUTH_METHOD="public"
    
    mkdir -p "$test_cache_dir"
    
    # Mock rate limit error message
    curl() {
        echo '{"message": "API rate limit exceeded"}200'
    
    # Mock rate limit check to always return true
    api_check_rate_limit() {
        return 0
    }
        return 0
    }
    
    run api_fetch_with_cache "https://api.github.com/test"
    
    [ "$status" -eq 1 ]
    
    # Cleanup
    rm -rf "$test_cache_dir"
}

@test "api_fetch_all_repos uses complete cache when available" {
    local test_cache_dir="/tmp/test-api-cache"
    export API_CACHE_DIR="$test_cache_dir"
    export API_CACHE_TTL=3600
    export GITHUB_AUTH_METHOD="public"
    
    mkdir -p "$test_cache_dir"
    
    local cache_key
    cache_key=$(api_cache_key "all_repos_users_testuser")
    local cache_file="$test_cache_dir/${cache_key}.json"
    
    echo '[{"name": "repo1"}, {"name": "repo2"}]' > "$cache_file"
    
    run api_fetch_all_repos "users" "testuser"
    
    [ "$status" -eq 0 ]
    # Extraire la dernière ligne qui contient le JSON
    local last_line=$(echo "$output" | tail -n1)
    [ "$last_line" = '[{"name": "repo1"}, {"name": "repo2"}]' ]
    
    # Cleanup
    rm -rf "$test_cache_dir"
}

@test "api_fetch_all_repos handles pagination correctly" {
    local test_cache_dir="/tmp/test-api-cache"
    export API_CACHE_DIR="$test_cache_dir"
    export API_CACHE_TTL=3600
    export GITHUB_AUTH_METHOD="public"
    
    mkdir -p "$test_cache_dir"
    
    # Mock paginated API responses
    curl() {
        case "$1" in
            *"page=1"*)
                echo '[{"name": "repo1"}, {"name": "repo2"}]200'
    
    # Mock rate limit check to always return true
    api_check_rate_limit() {
        return 0
    }
                ;;
            *"page=2"*)
                echo '[{"name": "repo3"}]200'
                ;;
            *)
                echo '[]200'
                ;;
        esac
        return 0
    }
    
    run api_fetch_all_repos "users" "testuser"
    
    [ "$status" -eq 0 ]
    # Should contain all repos from both pages
    # Extraire la dernière ligne qui contient le JSON
    local last_line=$(echo "$output" | tail -n1)
    echo "$last_line" | jq -e 'length == 3'
    
    # Cleanup
    rm -rf "$test_cache_dir"
}

@test "api_fetch_all_repos handles API failure gracefully" {
    local test_cache_dir="/tmp/test-api-cache"
    export API_CACHE_DIR="$test_cache_dir"
    export API_CACHE_TTL=3600
    export GITHUB_AUTH_METHOD="public"
    
    mkdir -p "$test_cache_dir"
    
    # Mock API failure
    curl() {
        echo '{"message": "API rate limit exceeded"}403'
        
        # Mock rate limit check to always return true
        api_check_rate_limit() {
            return 0
        }
        return 0
    }
    
    run api_fetch_all_repos "users" "testuser"
    
    [ "$status" -eq 0 ]
    # Extraire la dernière ligne qui contient le JSON
    local last_line=$(echo "$output" | tail -n1)
    [ "$last_line" = "[]" ]
    
    # Cleanup
    rm -rf "$test_cache_dir"
}

@test "api_fetch_all_repos returns partial results on failure" {
    local test_cache_dir="/tmp/test-api-cache"
    export API_CACHE_DIR="$test_cache_dir"
    export API_CACHE_TTL=3600
    export GITHUB_AUTH_METHOD="public"
    
    mkdir -p "$test_cache_dir"
    
    local call_count=0
    
    # Mock first page success, second page failure
    curl() {
        call_count=$((call_count + 1))
        case "$call_count" in
            1)
                echo '[{"name": "repo1"}, {"name": "repo2"}]200'
    
    # Mock rate limit check to always return true
    api_check_rate_limit() {
        return 0
    }
                ;;
            *)
                echo '{"message": "API rate limit exceeded"}403'
                ;;
        esac
        return 0
    }
    
    run api_fetch_all_repos "users" "testuser"
    
    [ "$status" -eq 0 ]
    # Should return partial results
        # Extraire la dernière ligne qui contient le JSON
    local last_line=$(echo "$output" | tail -n1)
    echo "$last_line" | jq -e 'length == 2'
    
    # Cleanup
    rm -rf "$test_cache_dir"
}

@test "api_fetch_all_repos validates JSON response structure" {
    local test_cache_dir="/tmp/test-api-cache"
    export API_CACHE_DIR="$test_cache_dir"
    export API_CACHE_TTL=3600
    export GITHUB_AUTH_METHOD="public"
    
    mkdir -p "$test_cache_dir"
    
    # Mock invalid JSON structure (not an array)
    curl() {
        echo '{"not": "an array"}200'
    
    # Mock rate limit check to always return true
    api_check_rate_limit() {
        return 0
    }
        return 0
    }
    
    run api_fetch_all_repos "users" "testuser"
    
    [ "$status" -eq 0 ]
        # Extraire la dernière ligne qui contient le JSON
    local last_line=$(echo "$output" | tail -n1)
    [ "$last_line" = "[]" ]
    
    # Cleanup
    rm -rf "$test_cache_dir"
}

@test "api_fetch_all_repos handles empty page correctly" {
    local test_cache_dir="/tmp/test-api-cache"
    export API_CACHE_DIR="$test_cache_dir"
    export API_CACHE_TTL=3600
    export GITHUB_AUTH_METHOD="public"
    
    mkdir -p "$test_cache_dir"
    
    # Mock empty page response
    curl() {
        echo '[]200'
        return 0
    }
    
    # Mock rate limit check to always return true
    api_check_rate_limit() {
        return 0
    }
    
    run api_fetch_all_repos "users" "testuser"
    
    [ "$status" -eq 0 ]
        # Extraire la dernière ligne qui contient le JSON
    local last_line=$(echo "$output" | tail -n1)
    [ "$last_line" = "[]" ]
    
    # Cleanup
    rm -rf "$test_cache_dir"
}

@test "api_fetch_all_repos saves complete cache" {
    local test_cache_dir="/tmp/test-api-cache"
    export API_CACHE_DIR="$test_cache_dir"
    export API_CACHE_TTL=3600
    export GITHUB_AUTH_METHOD="public"
    
    mkdir -p "$test_cache_dir"
    
    # Mock successful API response
    curl() {
        echo '[{"name": "repo1"}, {"name": "repo2"}]200'
    
    # Mock rate limit check to always return true
    api_check_rate_limit() {
        return 0
    }
        return 0
    }
    
    run api_fetch_all_repos "users" "testuser"
    
    [ "$status" -eq 0 ]
    
    # Check that cache was saved
    local cache_key
    cache_key=$(api_cache_key "all_repos_users_testuser")
    local cache_file="$test_cache_dir/${cache_key}.json"
    
    [ -f "$cache_file" ]
    [ "$(cat "$cache_file")" = '[{"name": "repo1"}, {"name": "repo2"}]' ]
    
    # Cleanup
    rm -rf "$test_cache_dir"
}
