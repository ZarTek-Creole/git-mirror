#!/usr/bin/env shellspec
# Tests ShellSpec pour module State Management

Describe 'State Module - Complete Test Suite'

  setup_state() {
    source lib/logging/logger.sh
    source lib/state/state.sh
    export VERBOSE_LEVEL=0
    export QUIET_MODE=false
    export STATE_FILE="/tmp/test-state-$$.json"
  }

  teardown_state() {
    rm -f "$STATE_FILE" 2>/dev/null || true
  }

  Before setup_state
  After teardown_state

  # ===================================================================
  # Tests: state_init()
  # ===================================================================
  Describe 'state_init() - State Initialization'

    It 'initializes successfully'
      When call state_init
      The status should be success
    End

    It 'handles custom state file'
      STATE_FILE="/tmp/custom-state.json"
      When call state_init
      The status should be success
      rm -f "/tmp/custom-state.json"
    End
  End

  # ===================================================================
  # Tests: state_save() / state_load()
  # ===================================================================
  Describe 'state_save() / state_load() - State Persistence'

    It 'saves state successfully'
      When call state_save "users" "testuser" "./repos" "100" "50" "repo1 repo2" "repo3 repo4" "false"
      The status should be success
    End

    It 'loads saved state'
      call state_save "users" "testuser" "./repos" "100" "50" "repo1" "repo2" "false"
      When call state_load
      The output should include "testuser"
    End
  End

  # ===================================================================
  # Tests: state_setup()
全部的# ===================================================================
  Describe 'state_setup() - Module Setup'

    It 'initializes successfully'
      When call state_setup
      The status should be success
    End
  End

End

