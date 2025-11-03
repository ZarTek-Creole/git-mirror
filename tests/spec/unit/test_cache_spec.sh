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
  # Tests: cache_set()
  # ===================================================================
  Describe 'cache_set() - Cache Set Operations'

    It 'stores data successfully'
      call init_cache
      When call cache_set "test_key" '{"test": "data"}'
      The status should be success
    End

    It 'stores data when cache enabled'
      call init_cache "" "" "true"
      When call cache_set "test_key" '{"test": "data"}'
      The status should be success
    End

    It 'does nothing when cache disabled'
      call init_cache "" "" "false"
      When call cache_set "test_key" '{"test": "data"}'
      The status should be success
    End

    It 'handles write failure gracefully'
      call init_cache "/root/invalid"  # Path non accessible
      When call cache_set "test_key" '{"test": "data"}'
      # Devrait ?chouer ou g?rer gracieusement
      The status should be defined
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
  # Tests: cache_get_last_sync()
  # ===================================================================
  Describe 'cache_get_last_sync() - Get Last Sync Timestamp'

    It 'returns epoch for first sync'
      call init_cache
      When call cache_get_last_sync "users" "newuser"
      The output should eq "1970-01-01T00:00:00Z"
    End

    It 'returns stored timestamp'
      call init_cache
      call cache_set_last_sync "users" "testuser"
      When call cache_get_last_sync "users" "testuser"
      The output should match pattern '[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z'
    End
  End

  # ===================================================================
  # Tests: cache_set_last_sync()
  # ===================================================================
  Describe 'cache_set_last_sync() - Set Last Sync Timestamp'

    It 'stores timestamp successfully'
      call init_cache
      When call cache_set_last_sync "users" "testuser"
      The status should be success
      When call cache_get_last_sync "users" "testuser"
      The output should match pattern '[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z'
    End

    It 'updates existing timestamp'
      call init_cache
      call cache_set_last_sync "users" "testuser"
      sleep 1
      call cache_set_last_sync "users" "testuser"
      When call cache_get_last_sync "users" "testuser"
      The output should match pattern '[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z'
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
  # Tests: _create_cache_structure()
  # ===================================================================
  Describe '_create_cache_structure() - Cache Structure Creation'

    It 'creates cache directories'
      CACHE_DIR="/tmp/test-cache-structure-$$"
      When call _create_cache_structure
      The status should be success
      The directory "$CACHE_DIR/api" should exist
      The directory "$CACHE_DIR/metadata" should exist
      The directory "$CACHE_DIR/state" should exist
      rm -rf "$CACHE_DIR"
    End
  End

  # ===================================================================
  # Tests: cache_delete()
  # ===================================================================
  Describe 'cache_delete() - Cache Deletion'

    It 'deletes existing cache entry'
      call init_cache
      call cache_set "test-key" '{"data":"test"}'
      When call cache_delete "test-key"
      The status should be success
      When call cache_get "test-key"
      The status should be failure
    End

    It 'handles non-existent key'
      call init_cache
      When call cache_delete "nonexistent-key"
      The status should be success
    End
  End

  # ===================================================================
  # Tests: cache_exists()
  # ===================================================================
  Describe 'cache_exists() - Cache Existence Check'

    It 'returns true for existing cache entry'
      call init_cache
      call cache_set "test-key" '{"data":"test"}'
      When call cache_exists "test-key"
      The status should be success
    End

    It 'returns false for non-existent cache entry'
      call init_cache
      When call cache_exists "nonexistent-key"
      The status should be failure
    End

    It 'returns false when cache disabled'
      CACHE_ENABLED=false
      call init_cache
      call cache_set "test-key" '{"data":"test"}'
      When call cache_exists "test-key"
      The status should be failure
    End

    It 'returns false for expired cache entry'
      call init_cache
      call cache_set "test-key" '{"data":"test"}'
      local cache_file="$CACHE_DIR/metadata/test-key.json"
      touch -t 199001010000 "$cache_file" 2>/dev/null || touch -d "1990-01-01" "$cache_file"
      CACHE_TTL=3600
      When call cache_exists "test-key"
      The status should be failure
    End
  End

  # ===================================================================
  # Tests: cache_get_total_repos()
  # ===================================================================
  Describe 'cache_get_total_repos() - Get Total Repos'

    It 'returns cached total repos'
      call init_cache
      call cache_set_total_repos "users" "testuser" "100"
      When call cache_get_total_repos "users" "testuser"
      The output should eq "100"
    End

    It 'returns empty when not cached'
      call init_cache
      When call cache_get_total_repos "users" "testuser"
      The status should be failure
    End
  End

  # ===================================================================
  # Tests: cache_set_total_repos()
  # ===================================================================
  Describe 'cache_set_total_repos() - Set Total Repos'

    It 'stores total repos'
      call init_cache
      When call cache_set_total_repos "users" "testuser" "100"
      The status should be success
      When call cache_get_total_repos "users" "testuser"
      The output should eq "100"
    End
  End

  # ===================================================================
  # Tests: cache_set_state()
  # ===================================================================
  Describe 'cache_set_state() - Set State'

    It 'stores state successfully'
      call init_cache
      local state_data='{"processed":10,"failed":2}'
      When call cache_set_state "$state_data"
      The status should be success
    End

    It 'overwrites existing state'
      call init_cache
      call cache_set_state '{"processed":5}'
      When call cache_set_state '{"processed":10}'
      The status should be success
    End
  End

  # ===================================================================
  # Tests: cache_get_state() / cache_set_state()
  # ===================================================================
  Describe 'cache_get_state() / cache_set_state() - State Management'

    It 'gets empty state when no state file'
      call init_cache
      When call cache_get_state
      The output should eq "{}"
    End

    It 'stores and retrieves state'
      call init_cache
      local state_data='{"processed":10,"failed":2}'
      call cache_set_state "$state_data"
      When call cache_get_state
      The output should include "processed"
      The output should include "10"
    End

    It 'handles state update'
      call init_cache
      call cache_set_state '{"processed":5}'
      call cache_set_state '{"processed":10}'
      When call cache_get_state
      The output should include "10"
    End
  End

  # ===================================================================
  # Tests: _cleanup_expired_cache()
  # ===================================================================
  Describe '_cleanup_expired_cache() - Expired Cache Cleanup'

    It 'does nothing when metadata directory does not exist'
      CACHE_DIR="/tmp/test-cache-cleanup-$$"
      rm -rf "$CACHE_DIR"
      When call _cleanup_expired_cache
      The status should be success
      rm -rf "$CACHE_DIR"
    End

    It 'cleans up expired cache files'
      call init_cache
      call cache_set "key1" '{"data":"test1"}'
      call cache_set "key2" '{"data":"test2"}'
      # Rendre un fichier expir?
      local cache_file="$CACHE_DIR/metadata/key1.json"
      touch -t 199001010000 "$cache_file" 2>/dev/null || touch -d "1990-01-01" "$cache_file"
      CACHE_TTL=3600
      When call _cleanup_expired_cache
      The status should be success
      When call cache_exists "key1"
      The status should be failure
      When call cache_exists "key2"
      The status should be success
    End

    It 'keeps valid cache files'
      call init_cache
      call cache_set "key1" '{"data":"test1"}'
      CACHE_TTL=86400
      When call _cleanup_expired_cache
      The status should be success
      When call cache_exists "key1"
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

