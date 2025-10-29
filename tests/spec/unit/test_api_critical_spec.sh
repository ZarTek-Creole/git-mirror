#!/usr/bin/env shellspec
# Tests ShellSpec pour module API GitHub (CRITIQUE)
# Objectif: Couverture maximale pour github_api.sh

Describe 'GitHub API Module - Critical Functions'

  setup_api() {
    source lib/logging/logger.sh
    source lib/cache/cache.sh
    source lib/auth/auth.sh
    source tests/spec/support/mocks/mock_curl.sh
    source lib/api/github_api.sh
    export VERBOSE_LEVEL=0
    export QUIET_MODE=false
    mkdir -p .git-mirror-cache/api
  }

  Before setup_api

  # ===================================================================
  # Tests: api_cache_key()
  # ===================================================================
  Describe 'api_cache_key()'

    It 'generates cache key from URL'
      When call api_cache_key "https://api.github.com/users/test/repos"
      The status should be success
      The output should match pattern "*test*repos*"
    End

    It 'replaces special characters in URL'
      When call api_cache_key "https://api.github.com/users/test/repos?page=1"
      The output should not match pattern "*/*"
      The output should not match pattern "*\?*"
    End
  End

  # ===================================================================
  # Tests: api_cache_valid()
  # ===================================================================
  Describe 'api_cache_valid()'

    It 'returns success for valid cache file'
      local cache_file=$(mktemp)
      touch "$cache_file"
      When call api_cache_valid "$cache_file" "3600"
      The status should be success
      rm -f "$cache_file"
    End

    It 'returns failure for non-existent file'
      When call api_cache_valid "/nonexistent/file.json" "3600"
      The status should be failure
    End

    It 'returns failure for expired cache'
      local cache_file=$(mktemp)
      # Set file mtime to 2 hours ago
      touch -t "$(date -d '2 hours ago' hidden %Y%m%d%H%M)" "$cache_file"
      When call api_cache_valid "$cache_file" "3600"
      The status should be failure
      rm -f "$cache_file"
    End
  End

  # ===================================================================
  # Tests: api_check_rate_limit()
  # ===================================================================
  Describe 'api_check_rate_limit()'

    It 'checks rate limit successfully'
      export GITHUB_AUTH_METHOD="public"
      When call api_check_rate_limit
      The status should be success
    End
  End

  # ===================================================================
  # Tests: api_fetch_with_cache()
  # ===================================================================
  Describe 'api_fetch_with_cache()'

    It 'fetches data without cache'
      export API_CACHE_DISABLED=true
      export GITHUB_AUTH_METHOD="public"
      When call api_fetch_with_cache "https://api.github.com/user"
      The status should be success
    End

    It 'uses cache when available and valid'
      export API_CACHE_DISABLED=false
      local cache_key=$(api_cache_key "https://test.com/data")
      local cache_file=".git-mirror-cache/api/${cache_key}.json"
      mkdir -p .git-mirror-cache/api
      echo '{"test":"data"}' > "$cache_file"
      When call api_fetch_with_cache "https://test.com/data"
      The status should be success
      The output should eq '{"test":"data"}'
    End
  End

  # ===================================================================
  # Tests: api_fetch_all_repos()
  # ===================================================================
  Describe 'api_fetch_all_repos()'

    It 'fetches all repos for user'
      export API_CACHE_DISABLED=true
      export GITHUB_AUTH_METHOD="public"
      When call api_fetch_all_repos "users" "testuser"
      The status should be success
      The output should include "["
    End
  End

  # ===================================================================
  # Tests: api_get_total_repos()
  # ===================================================================
  Describe 'api_get_total_repos()'

    It 'gets total repos count'
      export API_CACHE_DISABLED=true
      export GITHUB_AUTH_METHOD="public"
      When call api_get_total_repos "users" "testuser"
      The status should be success
      The output should match pattern "[0-9]+"
    End
  End

  # ===================================================================
  # Tests: api_setup()
  # ===================================================================
  Describe 'api_setup()'

    It 'initializes API module'
      When call api_setup
      The status should be success
    End
  End

End

