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
  # Tests: incremental_update_timestamp()
  # ===================================================================
  Describe 'incremental_update_timestamp() - Update Timestamp'

    It 'updates timestamp successfully'
      When call incremental_update_timestamp
      The status should be success
    End

    It 'creates sync file if missing'
      rm -f "$INCREMENTAL_LAST_SYNC_FILE"
      When call incremental_update_timestamp
      The status should be success
      The file "$INCREMENTAL_LAST_SYNC_FILE" should exist
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
  # Tests: incremental_filter_updated()
  # ===================================================================
  Describe 'incremental_filter_updated() - Filter Updated Repos'

    It 'returns all repos when disabled'
      INCREMENTAL_ENABLED=false
      local repos_json='[{"name":"repo1","updated_at":"2025-01-29T12:00:00Z"},{"name":"repo2","updated_at":"2025-01-28T12:00:00Z"}]'
      When call incremental_filter_updated "$repos_json"
      The status should be success
      The output should include "repo1"
      The output should include "repo2"
    End

    It 'filters repos by update time'
      INCREMENTAL_ENABLED=true
      call incremental_update_timestamp
      local last_sync
      last_sync=$(incremental_get_last_sync)
      local repos_json='[{"name":"repo1","pushed_at":"2025-01-29T12:00:00Z"},{"name":"repo2","pushed_at":"2025-01-28T12:00:00Z"}]'
      When call incremental_filter_updated "$repos_json" "$last_sync"
      The status should be success
    End

    It 'returns all repos when no last sync'
      INCREMENTAL_ENABLED=true
      local repos_json='[{"name":"repo1","pushed_at":"2025-01-29T12:00:00Z"}]'
      When call incremental_filter_updated "$repos_json" ""
      The status should be success
      The output should include "repo1"
    End

    It 'handles empty repos list'
      INCREMENTAL_ENABLED=true
      When call incremental_filter_updated "[]"
      The status should be success
      The output should eq "[]"
    End
  End

  # ===================================================================
  # Tests: incremental_get_stats()
  # ===================================================================
  Describe 'incremental_get_stats() - Incremental Statistics'

    It 'returns statistics when enabled'
      INCREMENTAL_ENABLED=true
      When call incremental_get_stats "100" "50" "2025-01-01T00:00:00Z"
      The status should be success
      The output should include "Statistiques Mode Incr?mental"
      The output should include "100"
      The output should include "50"
    End

    It 'returns disabled message when disabled'
      INCREMENTAL_ENABLED=false
      When call incremental_get_stats "100" "50" "2025-01-01T00:00:00Z"
      The status should be success
      The output should include "d?sactiv?"
    End
  End

  # ===================================================================
  # Tests: incremental_show_summary()
  # ===================================================================
  Describe 'incremental_show_summary() - Show Summary'

    It 'shows summary when enabled'
      INCREMENTAL_ENABLED=true
      call incremental_update_timestamp
      When call incremental_show_summary
      The status should be success
      The output should include "Mode incr?mental"
    End

    It 'shows disabled message when disabled'
      INCREMENTAL_ENABLED=false
      When call incremental_show_summary
      The status should be success
      The output should include "d?sactiv?"
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

