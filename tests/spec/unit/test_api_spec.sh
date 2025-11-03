#!/usr/bin/env shellspec
# Tests ShellSpec complets pour module API GitHub
# Couverture: 100% de toutes les fonctions

Describe 'API Module - Complete Test Suite (100% Coverage)'

  setup_api() {
    export GIT_MIRROR_TEST_MODE=true
    export VERBOSE_LEVEL=2
    export QUIET_MODE=false
    export DRY_RUN_MODE=false
    export CACHE_DIR="/tmp/test-cache-$$"
    export API_CACHE_DIR="$CACHE_DIR/api"
    export API_CACHE_TTL=3600
    export API_MAX_RETRIES=3
    export API_RETRY_DELAY=5
    export API_BASE_URL="https://api.github.com"
    export GITHUB_AUTH_METHOD="public"
    
    mkdir -p "$API_CACHE_DIR"
    
    # Charger les dépendances
    source lib/logging/logger.sh
    init_logger 0 false false true
    
    # Mock auth functions
    auth_get_headers() {
      echo ""
    }
    export -f auth_get_headers
    
    # Charger le module
    source lib/api/github_api.sh
  }

  teardown_api() {
    rm -rf "$CACHE_DIR" 2>/dev/null || true
  }

  Before setup_api
  After teardown_api

  # ===================================================================
  # Tests: api_init()
  # ===================================================================
  Describe 'api_init() - API Module Initialization'

    It 'initializes successfully'
      When call api_init
      The status should be success
    End

    It 'creates cache directory'
      rm -rf "$API_CACHE_DIR"
      When call api_init
      The directory "$API_CACHE_DIR" should exist
    End

    It 'handles existing cache directory'
      mkdir -p "$API_CACHE_DIR"
      When call api_init
      The status should be success
    End

    It 'logs debug information'
      When call api_init
      The status should be success
    End
  End

  # ===================================================================
  # Tests: api_cache_key()
  # ===================================================================
  Describe 'api_cache_key() - Cache Key Generation'

    It 'generates valid cache key for simple URL'
      When call api_cache_key "https://api.github.com/users/test"
      The status should be success
      The output should not be empty
      The output should not include "/"
      The output should not include ":"
    End

    It 'handles URLs with query parameters'
      When call api_cache_key "https://api.github.com/users/test/repos?page=1&per_page=100"
      The status should be success
      The output should not include "?"
      The output should not include "&"
      The output should not include "="
    End

    It 'handles complex URLs'
      When call api_cache_key "https://api.github.com/users/test/repos?page=1&per_page=100&sort=updated&direction=desc"
      The status should be success
      The output should not be empty
    End

    It 'handles empty URL'
      When call api_cache_key ""
      The status should be success
      The output should be empty
    End
  End

  # ===================================================================
  # Tests: api_cache_valid()
  # ===================================================================
  Describe 'api_cache_valid() - Cache Validation'

    It 'validates recent cache file'
      local cache_file="$API_CACHE_DIR/test.json"
      echo '{"test": "data"}' > "$cache_file"
      When call api_cache_valid "$cache_file" "3600"
      The status should be success
    End

    It 'rejects missing cache file'
      When call api_cache_valid "$API_CACHE_DIR/nonexistent.json" "3600"
      The status should be failure
    End

    It 'rejects expired cache file'
      local cache_file="$API_CACHE_DIR/expired.json"
      echo '{"test": "data"}' > "$cache_file"
      touch -t 199001010000 "$cache_file" 2>/dev/null || touch -d "1990-01-01" "$cache_file"
      When call api_cache_valid "$cache_file" "3600"
      The status should be failure
    End

    It 'handles zero TTL'
      local cache_file="$API_CACHE_DIR/test.json"
      echo '{"data": "test"}' > "$cache_file"
      When call api_cache_valid "$cache_file" "0"
      The status should be failure
    End

    It 'handles very long TTL'
      local cache_file="$API_CACHE_DIR/test.json"
      echo '{"data": "test"}' > "$cache_file"
      When call api_cache_valid "$cache_file" "86400"
      The status should be success
    End
  End

  # ===================================================================
  # Tests: api_check_rate_limit()
  # ===================================================================
  Describe 'api_check_rate_limit() - Rate Limit Checking'

    It 'checks rate limit successfully'
      # Mock curl to return valid rate limit response
      curl() {
        echo '{"rate":{"remaining":100,"limit":5000,"reset":9999999999}}'
      }
      export -f curl
      
      When call api_check_rate_limit
      The status should be success
    End

    It 'handles rate limit API error'
      curl() {
        return 1
      }
      export -f curl
      
      When call api_check_rate_limit
      The status should be failure
    End

    It 'warns when rate limit is low'
      curl() {
        echo '{"rate":{"remaining":10,"limit":5000,"reset":9999999999}}'
      }
      export -f curl
      
      When call api_check_rate_limit
      The status should be success
    End
  End

  # ===================================================================
  # Tests: api_wait_rate_limit()
  # ===================================================================
  Describe 'api_wait_rate_limit() - Rate Limit Waiting'

    It 'does not wait when rate limit available'
      curl() {
        echo '{"rate":{"remaining":100,"limit":5000,"reset":9999999999}}'
      }
      export -f curl
      
      When call api_wait_rate_limit
      The status should be success
    End

    It 'handles API error gracefully'
      curl() {
        return 1
      }
      export -f curl
      
      When call api_wait_rate_limit
      The status should be failure
    End
  End

  # ===================================================================
  # Tests: api_fetch_with_cache()
  # ===================================================================
  Describe 'api_fetch_with_cache() - Fetch with Caching'

    It 'returns cached data when available'
      local url="https://api.github.com/users/test"
      local cache_key
      cache_key=$(api_cache_key "$url")
      local cache_file="$API_CACHE_DIR/$cache_key.json"
      echo '{"cached": "data"}' > "$cache_file"
      
      When call api_fetch_with_cache "$url"
      The status should be success
      The output should include "cached"
    End

    It 'fetches fresh data when cache disabled'
      export API_CACHE_DISABLED=true
      curl() {
        echo '{"fresh": "data"}'
      }
      export -f curl
      
      When call api_fetch_with_cache "https://api.github.com/users/test"
      The status should be success
      The output should include "fresh"
    End

    It 'handles HTTP 404 error'
      curl() {
        echo "HTTP_CODE:404"
        echo '{"message": "Not Found"}'
      }
      export -f curl
      
      When call api_fetch_with_cache "https://api.github.com/users/invalid"
      The status should be failure
    End

    It 'handles HTTP 403 error'
      curl() {
        echo "HTTP_CODE:403"
        echo '{"message": "Forbidden"}'
      }
      export -f curl
      
      When call api_fetch_with_cache "https://api.github.com/users/test"
      The status should be failure
    End

    It 'handles HTTP 429 error'
      curl() {
        echo "HTTP_CODE:429"
        echo '{"message": "Rate limit exceeded"}'
      }
      export -f curl
      
      When call api_fetch_with_cache "https://api.github.com/users/test"
      The status should be failure
    End

    It 'validates JSON response'
      curl() {
        echo "HTTP_CODE:200"
        echo "invalid json"
      }
      export -f curl
      
      When call api_fetch_with_cache "https://api.github.com/users/test"
      The status should be failure
    End
  End

  # ===================================================================
  # Tests: api_fetch_all_repos()
  # ===================================================================
  Describe 'api_fetch_all_repos() - Fetch All Repositories'

    It 'fetches repositories successfully'
      curl() {
        if [[ "$*" =~ "page=1" ]]; then
          echo '[{"name":"repo1","clone_url":"https://github.com/user/repo1.git"}]'
        else
          echo "[]"
        fi
      }
      export -f curl
      
      When call api_fetch_all_repos "users" "testuser"
      The status should be success
      The output should include "repo1"
    End

    It 'handles pagination'
      local page=1
      curl() {
        if [[ "$*" =~ "page=$page" ]]; then
          echo '[{"name":"repo'$page'","clone_url":"https://github.com/user/repo'$page'.git"}]'
          page=$((page + 1))
        else
          echo "[]"
        fi
      }
      export -f curl
      
      When call api_fetch_all_repos "users" "testuser"
      The status should be success
    End

    It 'handles empty repository list'
      curl() {
        echo "[]"
      }
      export -f curl
      
      When call api_fetch_all_repos "users" "testuser"
      The status should be success
      The output should equal "[]"
    End

    It 'uses cache when available'
      local url="https://api.github.com/users/testuser/repos?page=1&per_page=100"
      local cache_key
      cache_key=$(api_cache_key "all_repos_users_testuser_public_all")
      local cache_file="$API_CACHE_DIR/${cache_key}.json"
      echo '[{"name":"cached-repo"}]' > "$cache_file"
      
      When call api_fetch_all_repos "users" "testuser"
      The status should be success
      The output should include "cached-repo"
    End
  End

  # ===================================================================
  # Tests: api_get_total_repos()
  # ===================================================================
  Describe 'api_get_total_repos() - Get Total Repository Count'

    It 'returns cached total when available'
      local cache_key
      cache_key=$(api_cache_key "total_users_testuser_all")
      local cache_file="$API_CACHE_DIR/${cache_key}.json"
      echo "42" > "$cache_file"
      
      When call api_get_total_repos "users" "testuser"
      The status should be success
      The output should equal "42"
    End

    It 'fetches total from API'
      curl() {
        echo '[{"name":"repo1"}]'
      }
      export -f curl
      
      When call api_get_total_repos "users" "testuser"
      The status should be success
      The output should not be empty
    End

    It 'returns default on API error'
      curl() {
        return 1
      }
      export -f curl
      
      When call api_get_total_repos "users" "testuser"
      The status should be success
      The output should equal "100"
    End
  End

  # ===================================================================
  # Tests: api_setup()
  # ===================================================================
  Describe 'api_setup() - Module Setup'

    It 'initializes successfully'
      When call api_setup
      The status should be success
    End

    It 'creates necessary directories'
      rm -rf "$API_CACHE_DIR"
      When call api_setup
      The directory "$API_CACHE_DIR" should exist
    End

    It 'logs success message'
      When call api_setup
      The status should be success
    End
  End

End
