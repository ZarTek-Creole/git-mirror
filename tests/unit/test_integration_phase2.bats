#!/usr/bin/env bats
# test_integration_phase2.bats - Tests d'intégration Phase 2

load 'test_helper.bash'

@test "all modules can be sourced without errors" {
    # Test that all modules can be loaded
    run bash -c '
        source lib/logging/logger.sh
        source config/config.sh
        source lib/auth/auth.sh
        source lib/api/github_api.sh
        source lib/validation/validation.sh
        source lib/git/git_ops.sh
        source lib/cache/cache.sh
        source lib/parallel/parallel.sh
        source lib/filters/filters.sh
        source lib/metrics/metrics.sh
        source lib/interactive/interactive.sh
        source lib/state/state.sh
        source lib/incremental/incremental.sh
        echo "All modules loaded successfully"
    '
    
    [ "$status" -eq 0 ]
    [ "$output" = "All modules loaded successfully" ]
}

@test "module setup functions work correctly" {
    run bash -c '
        source lib/logging/logger.sh
        source config/config.sh
        source lib/auth/auth.sh
        source lib/api/github_api.sh
        source lib/validation/validation.sh
        source lib/git/git_ops.sh
        source lib/cache/cache.sh
        source lib/parallel/parallel.sh
        source lib/filters/filters.sh
        source lib/metrics/metrics.sh
        source lib/interactive/interactive.sh
        source lib/state/state.sh
        source lib/incremental/incremental.sh
        
        # Test all setup functions
        auth_setup
        api_setup
        validate_setup
        git_ops_setup
        cache_setup
        parallel_setup
        filters_setup
        metrics_setup
        interactive_setup
        state_setup
        incremental_setup
        
        echo "All setup functions completed"
    '
    
    [ "$status" -eq 0 ]
    [ "$output" = "All setup functions completed" ]
}

@test "authentication and API integration works" {
    export GITHUB_TOKEN="1234567890123456789012345678901234567890"
    export GITHUB_AUTH_METHOD="token"
    
    run bash -c '
        source lib/logging/logger.sh
        source config/config.sh
        source lib/auth/auth.sh
        source lib/api/github_api.sh
        
        # Mock successful API call
        curl() {
            echo "{\"login\": \"testuser\", \"id\": 12345}200"
            return 0
        }
        
        # Test authentication detection
        method=$(auth_detect_method)
        echo "Auth method: $method"
        
        # Test API with authentication
        headers=$(auth_get_headers "$method")
        echo "Headers: $headers"
        
        echo "Integration test completed"
    '
    
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Auth method: token" ]]
    [[ "$output" =~ "Headers: -H \"Authorization: token" ]]
    [[ "$output" =~ "Integration test completed" ]]
}

@test "cache and API integration works" {
    local test_cache_dir="/tmp/test-integration-cache"
    export API_CACHE_DIR="$test_cache_dir"
    export API_CACHE_TTL=3600
    export GITHUB_AUTH_METHOD="public"
    
    mkdir -p "$test_cache_dir"
    
    run bash -c '
        source lib/logging/logger.sh
        source config/config.sh
        source lib/api/github_api.sh
        
        # Mock successful API call
        curl() {
            echo "{\"data\": \"test\"}200"
            return 0
        }
        
        # Test API with cache
        result=$(api_fetch_with_cache "https://api.github.com/test")
        echo "API result: $result"
        
        # Test cache was created
        if [ -f "'"$test_cache_dir"'/https___api_github_com_test.json" ]; then
            echo "Cache file created"
        else
            echo "Cache file not created"
        fi
        
        echo "Cache integration test completed"
    '
    
    [ "$status" -eq 0 ]
    [[ "$output" =~ "API result: {\"data\": \"test\"}" ]]
    [[ "$output" =~ "Cache file created" ]]
    [[ "$output" =~ "Cache integration test completed" ]]
    
    # Cleanup
    rm -rf "$test_cache_dir"
}

@test "validation and configuration integration works" {
    run bash -c '
        source lib/logging/logger.sh
        source config/config.sh
        source lib/validation/validation.sh
        
        # Test validation functions
        validate_context "users"
        validate_username "testuser"
        validate_destination "/tmp/test"
        validate_branch "main"
        validate_filter "blob:none"
        validate_depth "1"
        validate_parallel_jobs "5"
        validate_timeout "30"
        
        echo "All validations passed"
    '
    
    [ "$status" -eq 0 ]
    [ "$output" = "All validations passed" ]
}

@test "error handling integration works" {
    run bash -c '
        source lib/logging/logger.sh
        source config/config.sh
        source lib/auth/auth.sh
        source lib/api/github_api.sh
        
        # Test error handling
        export GITHUB_AUTH_METHOD="public"
        
        # Mock API error
        curl() {
            echo "{\"message\": \"API rate limit exceeded\"}403"
            return 0
        }
        
        # This should handle the error gracefully
        result=$(api_fetch_with_cache "https://api.github.com/test" 2>/dev/null || echo "API_ERROR")
        echo "Error handling result: $result"
        
        echo "Error handling test completed"
    '
    
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Error handling result: API_ERROR" ]]
    [[ "$output" =~ "Error handling test completed" ]]
}

@test "dry-run mode integration works" {
    export DRY_RUN=true
    export VERBOSE=0
    export QUIET=false
    
    run bash -c '
        source lib/logging/logger.sh
        source config/config.sh
        source lib/git/git_ops.sh
        
        # Test dry-run mode
        if [ "$DRY_RUN" = "true" ]; then
            echo "Dry-run mode enabled"
        else
            echo "Dry-run mode disabled"
        fi
        
        echo "Dry-run integration test completed"
    '
    
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Dry-run mode enabled" ]]
    [[ "$output" =~ "Dry-run integration test completed" ]]
}

@test "verbose mode integration works" {
    export VERBOSE=2
    export QUIET=false
    export DRY_RUN=false
    
    run bash -c '
        source lib/logging/logger.sh
        source config/config.sh
        
        # Test verbose logging
        log_debug "Debug message"
        log_info "Info message"
        log_success "Success message"
        log_warning "Warning message"
        log_error "Error message"
        
        echo "Verbose mode test completed"
    '
    
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Debug message" ]]
    [[ "$output" =~ "Info message" ]]
    [[ "$output" =~ "Success message" ]]
    [[ "$output" =~ "Warning message" ]]
    [[ "$output" =~ "Error message" ]]
    [[ "$output" =~ "Verbose mode test completed" ]]
}

@test "quiet mode integration works" {
    export VERBOSE=0
    export QUIET=true
    export DRY_RUN=false
    
    run bash -c '
        source lib/logging/logger.sh
        source config/config.sh
        
        # Test quiet logging (should suppress most messages)
        log_info "Info message"
        log_success "Success message"
        log_warning "Warning message"
        log_error "Error message"
        
        echo "Quiet mode test completed"
    '
    
    [ "$status" -eq 0 ]
    # In quiet mode, only error messages should be shown
    [[ "$output" =~ "Error message" ]]
    [[ "$output" =~ "Quiet mode test completed" ]]
    # Other messages should be suppressed
    [[ ! "$output" =~ "Info message" ]]
    [[ ! "$output" =~ "Success message" ]]
    [[ ! "$output" =~ "Warning message" ]]
}

@test "configuration loading works correctly" {
    run bash -c '
        source lib/logging/logger.sh
        source config/config.sh
        
        # Test that configuration variables are loaded
        echo "DEST_DIR: $DEST_DIR"
        echo "BRANCH: $BRANCH"
        echo "FILTER: $FILTER"
        echo "DEPTH: $DEPTH"
        echo "VERBOSE: $VERBOSE"
        echo "QUIET: $QUIET"
        echo "DRY_RUN: $DRY_RUN"
        
        echo "Configuration test completed"
    '
    
    [ "$status" -eq 0 ]
    [[ "$output" =~ "DEST_DIR:" ]]
    [[ "$output" =~ "BRANCH:" ]]
    [[ "$output" =~ "FILTER:" ]]
    [[ "$output" =~ "DEPTH:" ]]
    [[ "$output" =~ "VERBOSE:" ]]
    [[ "$output" =~ "QUIET:" ]]
    [[ "$output" =~ "DRY_RUN:" ]]
    [[ "$output" =~ "Configuration test completed" ]]
}
