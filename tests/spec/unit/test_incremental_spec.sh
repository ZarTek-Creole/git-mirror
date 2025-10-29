#!/usr/bin/env shellspec
# Tests ShellSpec pour module Incremental

Describe 'Incremental Module - Complete Test Suite'

  setup_incremental() {
    source lib/logging/logger.sh
    source lib/incremental/incremental.sh
    export VERBOSE_LEVEL=0
    export QUIET_MODE=false
    export INCREMENTAL_ENABLED=true
    export INCREMENTAL_CACHE_DIR="/tmp/test-incremental-$$"
  }

  teardown_incremental() {
    rm -rf "$INCREMENTAL_CACHE_DIR" 2>/dev/null || true
  }

  Before setup_incremental
  After teardown_incremental

  # ===================================================================
  # Tests: incremental_init()
  # ===================================================================
  Describe 'incremental_init() - Incremental Initialization'

    It 'initializes successfully'
      When call incremental_init
      The status should be success
    End

    It 'creates cache directory'
      call incremental_init
      When call test -d "$INCREMENTAL_CACHE_DIR"
      The status should be success
    End
  End

  # ===================================================================
  # Tests: incremental_get_last_sync() / incremental_update_timestamp()
  # ===================================================================
  Describe 'incremental_get_last_sync() / incremental_update_timestamp()'

    It 'returns empty for first sync'
      When call incremental_get_last_sync
      The output should eq ""
    End

    It 'stores and retrieves timestamp'
      call incremental_update_timestamp
      When call incremental_get_last_sync
      The output should match pattern '[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z'
    End
  End

  # ===================================================================
  # Tests: incremental_is_repo_updated()
  # ===================================================================
  Describe 'incremental_is_repo_updated() - Repository Update Check'

    It 'returns true when disabled'
      INCREMENTAL_ENABLED=false
      When call incremental_is_repo_updated "testrepo" "2024-01-01T00:00:00Z" "2023-01-01T00:00:00Z"
      The status should be success
    End

    It 'returns true for recently updated repo'
      INCREMENTAL_ENABLED=true
      When call incremental_is_repo_updated "testrepo" "2025-01-29T12:00:00Z" "2025-01-28T12:00:00Z"
      The status should be success
    End

    It 'returns false for old repo'
      INCREMENTAL_ENABLED=true
      When call incremental_is_repo_updated "testrepo" "2025-01-28T12:00:00Z" "2025-01-29T12:00:00Z"
      The status should be failure
    End
  End

  # ===================================================================
  # Tests: incremental_setup()
  # ===================================================================
  Describe 'incremental_setup() - Module Setup'

    It 'initializes successfully'
      When call incremental_setup
      The status should be success
    End

    It 'works when disabled'
      INCREMENTAL_ENABLED=false
      When call incremental_setup
      Internal status should be success
    End
  End

  # ===================================================================
  # Tests: incremental_cleanup()
  # ===================================================================
  Describe 'incremental_cleanup() - Cache Cleanup'

    It 'cleans up cache directory'
      call incremental_init
      When call incremental_cleanup
      The status should be success
    End
  End

End

