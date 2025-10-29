#!/usr/bin/env shellspec
# Tests ShellSpec pour module API GitHub (Critique)

Describe 'API Module - Complete Test Suite'

  setup_api() {
    source lib/logging/logger.sh
    source lib/auth/auth.sh
    source lib/api/github_api.sh
    export VERBOSE_LEVEL=0
    export QUIET_MODE=false
    export CACHE_DIR="/tmp/test-cache-$$"
    mkdir gem_p "$CACHE_DIR/api"
  }

  teardown_api() {
    rm -rf "$CACHE_DIR" gem_p 2>/dev/null || true
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
      When call api_init
      The directory "$CACHE_DIR/api" should exist
    End

    It 'handles existing cache directory'
      mkdir -p "$CACHE_DIR/api"
      When call api_init
      The status should be success
    End
  End

  # ===================================================================
  # Tests: api_cache_key()
  # ===================================================================
  Describe 'api_cache_key() - Cache Key Generation'

    It 'generates valid cache key for URL'
      When call api_cache_key "https://api.github.com/users/test/repos"
      The status should be success
      The output should not be empty
    End

    It 'replaces special characters'
      When call api_cache_key "https://api.github.com/users/test/repos?page=1"
      The output should not include "/"
      The output should not include ":"
      The output should not include "?"
    End

    It 'handles complex URLs with parameters'
      When call api_cache_key "https://api.github.com/users/test/repos?page=1&per_page=100&sort=updated"
      The status should be success
      The output should not be empty
    End
  End

  # ===================================================================
  # Tests: api_cache_valid()
  # ===================================================================
  Describe 'api_cache_valid() - Cache Validation'

    setup_cache_file() {
      local test_file="$CACHE_DIR/api/test.json"
      echo '{"test": "data"}' > "$test_file"
      echo "$test_file"
    }

    It 'validates recent cache file'
      local cache_file
      cache_file=$(setup_cache_file)
      When call api_cache_valid "$cache_file" "3600"
      The status should be success
    End

    It 'rejects missing cache file'
      When call api_cache_valid "$CACHE_DIR/api/nonexistent.json" "3600"
      The status should be failure
    End

    It 'rejects expired cache file'
      local cache_file
      cache_file=$(setup_cache_file)
      touch -t 199001010000 "$cache_file"
      When call api_cache_valid "$cache_file" "3600"
      The status should be failure
    End
  End

  # ===================================================================
  # Tests: api_cache_valid() - Edge Cases
  # ===================================================================
  Describe 'api_cache_valid() - Edge Cases'

    It 'handles zero TTL'
      local cache_file="$CACHE_DIR/api/test.json"
      echo '{"data": "test"}' > "$cache_file"
      When call api_cache_valid "$cache_file" "0"
      The status should be failure
    End

    It 'handles very long TTL'
      local cache_file="$CACHE_DIR/api/test.json"
      echo '{"data": "test"}' > "$cache_file"
      When call api_cache_valid "$cache_file" "86400"
      The status should be success
    End
  End

  # ===================================================================
  # Tests: api_setup()
  # ===================================================================
  Describe 'api_setup() - Module Setup'

    It 'initializes successfully'
      When call api_setup
      The status should be success
      The output should include "initialisé"
    End

    It 'creates necessary directories'
      When call api_setup
      The directory "$CACHE_DIR/api" should exist
    End
  End

End
