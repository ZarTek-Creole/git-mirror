#!/usr/bin/env shellspec
# Tests ShellSpec pour module Cache Management

Describe 'Cache Module - Complete Test Suite'

  setup_cache() {
    source lib/logging/logger.sh
    source lib/cache/cache.sh
    export CACHE_DIR="/tmp/test-cache-$$"
    export VERBOSE_LEVEL=0
    export QUIET_MODE=false
  }

  teardown_cache() {
    rm -rf "$CACHE_DIR" 2>/dev/null || true
  }

  Before setup_cache
  After teardown_cache

  # ===================================================================
  # Tests: init_cache()
  # ===================================================================
  Describe 'init_cache() - Cache Initialization'

    It 'initializes with default values'
      When call init_cache
      The status should be success
    End

    It 'creates cache directories'
      When call init_cache "/tmp/cache-test"
      The directory "/tmp/cache-test/api" should exist
      The directory "/tmp/cache-test/metadata" should exist
      The directory "/tmp/cache-test/state" should exist
      rm -rf "/tmp/cache-test"
    End

    It 'accepts custom cache directory'
      When call init_cache "/tmp/custom-cache"
      The status should be success
      rm -rf "/tmp/custom-cache"
    End

    It 'accepts custom TTL'
      When call init_cache "" "7200"
      The status should be success
    End

    It 'can be disabled'
      When call init_cache "" "" "false"
      The status should be success
    End
  End

  # ===================================================================
  # Tests: cache_get() / cache_set()
  # ===================================================================
  Describe 'cache_get() / cache_set() - Cache Operations'

    It 'stores and retrieves data'
      call init_cache
      call cache_set "test_key" '{"test": "data"}'
      When call cache_get "test_key"
      The status should be success
      The output should include "test"
    End

    It 'returns failure for non-existent key'
      call init_cache
      When call cache_get "nonexistent_key"
      The status should be failure
    End

    It 'returns failure for expired cache'
      call init_cache "" "1"  # TTL 1 seconde
      call cache_set "expiring_key" '{"data": "test"}'
      sleep 2
      When call cache_get "expiring_key"
      The status should be failure
    End

    It 'respects disabled cache'
      call init_cache "" "" "false"
      call cache_set "disabled_key" '{"data": "test"}'
      When call cache_get "disabled_key"
      The status should be failure
    End
  End

  # ===================================================================
  # Tests: cache_exists()
  # ===================================================================
  Describe 'cache_exists() - Cache Key Existence'

    It 'returns success for existing key'
      call init_cache
      call cache_set "existing_key" '{"data": "test"}'
      When call cache_exists "existing_key"
      The status should be success
    End

    It 'returns failure for non-existing key'
      call init_cache
      When call cache_exists "nonexistent_key"
      The status should be failure
    End

    It 'returns failure when cache disabled'
      call init_cache "" "" "false"
      When call cache_exists "any_key"
      The status should be failure
    End
  End

  # ===================================================================
  # Tests: cache_delete()
  # ===================================================================
  Describe 'cache_delete() - Cache Key Deletion'

    It 'deletes existing key'
      call init_cache
      call cache_set "delete_me" '{"data": "test"}'
      call cache_delete "delete_me"
      When call cache_exists "delete_me"
      The status should be failure
    End

    It 'handles deletion of non-existent key'
      call init_cache
      When call cache_delete "nonexistent_key"
      The status should be success
    End
  End

  # ===================================================================
  # Tests: cache_get_total_repos() / cache_set_total_repos()
  # ===================================================================
  Describe 'cache_get_total_repos() / cache_set_total_repos()'

    It 'stores and retrieves total repos'
      call init_cache
      call cache_set_total_repos "users" "testuser" "150"
      When call cache_get_total_repos "users" "testuser"
      The status should be success
      The output should eq "150"
    End

    It 'returns different values for different users'
      call init_cache
      call cache_set_total_repos "users" "user1" "100"
      call cache_set_total_repos "users" "user2" "200"
      When call cache_get_total_repos "users" "user1"
      The output should eq "100"
    End
  End

  # ===================================================================
  # Tests: cache_get_last_sync() / cache_set_last_sync()
  # ===================================================================
  Describe 'cache_get_last_sync() / cache_set_last_sync()'

    It 'stores and retrieves last sync timestamp'
      call init_cache
      call cache_set_last_sync "users" "testuser"
      When call cache_get_last_sync "users" "testuser"
      The output should match pattern '[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z'
    End

    It 'returns epoch for first sync'
      call init_cache
      When call cache_get_last_sync "users" "newuser"
      The output should eq "1970-01-01T00:00:00Z"
    End
  End

  # ===================================================================
  # Tests: cache_clear()
  # ===================================================================
  Describe 'cache_clear() - Cache Clearing'

    It 'clears the entire cache'
      call init_cache
      call cache_set "key1" '{"data": "test"}'
      call cache_set "key2" '{"data": "test2"}'
      call cache_clear
      When call cache_exists "key1"
      The status should be failure
    End

    It 'resets cache hit counters'
      call init_cache
      call cache_set "test_key" '{"data": "test"}'
      call cache_get "test_key"
      call cache_clear
      When call get_cache_stats
      The output should include "Cache hits: 0"
    End
  End

  # ===================================================================
  # Tests: get_cache_stats()
  # ===================================================================
  Describe 'get_cache_stats() - Cache Statistics'

    It 'displays cache statistics'
      call init_cache
      call cache_set "key1" '{"data": "test"}'
      call cache_get "key1"
      call cache_get "nonexistent"
      When call get_cache_stats
      The output should include "Cache Statistics:"
      The output should include "Cache hits:"
      The output should include "Cache misses:"
    End

    It 'calculates correct hit rate'
      call init_cache
      call cache_set "key1" '{"data": "test"}'
      call cache_get "key1"  # Hit
      call cache_get "key1"  # Hit
      call cache_get "nonexistent"  # Miss
      When call get_cache_stats
      The output should include "Hit rate:"
    End
  End

  # ===================================================================
  # Tests: cache_verify()
  # ===================================================================
  Describe 'cache_verify() - Cache Verification'

    It 'verifies valid cache directory'
      call init_cache "/tmp/verify-test"
      When call cache_verify
      The status should be success
      rm -rf "/tmp/verify-test"
    End

    It 'detects missing cache directory'
      CACHE_DIR="/tmp/missing-cache"
      When call cache_verify
      The status should be failure
    End
  End

  # ===================================================================
  # Tests: cache_setup()
  # ===================================================================
  Describe 'cache_setup() - Module Setup'

    It 'initializes successfully'
      When call cache_setup
      The status should be success
    End
  End

  # ===================================================================
  # Tests: get_cache_module_info()
  # ===================================================================
  Describe 'get_cache_module_info() - Module Information'

    It 'displays module information'
      call init_cache
      When call get_cache_module_info
      The output should include "Module: cache_management"
      The output should include "Cache directory:"
    End
  End

End

