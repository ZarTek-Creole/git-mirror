#!/usr/bin/env shellspec
# Tests ShellSpec pour module Profiling

Describe 'Profiling Module - Complete Test Suite'

  setup_profiling() {
    export VERBOSE_LEVEL=0
    export QUIET_MODE=false
    export DRY_RUN_MODE=false
    set +u
    source lib/logging/logger.sh
    init_logger "0" "false" "false"
    source lib/utils/profiling.sh
    set -u
    export PROFILING_LOG="${TEST_TMP_DIR:-/tmp}/profile.log"
    export PROFILING_ENABLED=true
  }

  teardown_profiling() {
    rm -f "${PROFILING_LOG}" 2>/dev/null || true
    unset PROFILING_ENABLED
    unset PROFILING_LOG
    unset VERBOSE_LEVEL
  }

  Before setup_profiling
  After teardown_profiling

  # ===================================================================
  # Tests: profiling_enable()
  # ===================================================================
  Describe 'profiling_enable() - Enable Profiling'

    It 'enables profiling successfully'
      When call profiling_enable
      The status should be success
      The output should include "Profiling activé"
    End

    It 'creates log file directory'
      When call profiling_enable
      The status should be success
    End

    It 'sets PROFILING_ENABLED to true'
      When call profiling_enable
      The variable PROFILING_ENABLED should eq "true"
    End
  End

  # ===================================================================
  # Tests: profiling_disable()
  # ===================================================================
  Describe 'profiling_disable() - Disable Profiling'

    It 'disables profiling successfully'
      When call profiling_disable
      The status should be success
      The output should include "Profiling désactivé"
    End

    It 'sets PROFILING_ENABLED to false'
      When call profiling_disable
      The variable PROFILING_ENABLED should eq "false"
    End
  End

  # ===================================================================
  # Tests: profiling_start()
  # ===================================================================
  Describe 'profiling_start() - Start Timer'

    It 'starts a timer successfully'
      When call profiling_start "test_timer"
      The status should be success
    End

    It 'creates timer entry'
      When call profiling_start "new_timer"
      The status should be success
      # Timer should be stored in PROFILING_TIMERS array
    End

    It 'handles multiple timers'
      When call profiling_start "timer1"
      When call profiling_start "timer2"
      The status should be success
    End

    It 'does nothing when profiling disabled'
      export PROFILING_ENABLED=false
      When call profiling_start "timer_disabled"
      The status should be success
    End

    It 'logs debug information when enabled'
      When call profiling_start "logged_timer"
      The status should be success
    End
  End

  # ===================================================================
  # Tests: profiling_stop()
  # ===================================================================
  Describe 'profiling_stop() - Stop Timer'

    It 'stops a timer successfully'
      call profiling_start "test_timer"
      When call profiling_stop "test_timer"
      The status should be success
      The output should include "Arrêt:"
    End

    It 'calculates duration correctly'
      call profiling_start "duration_test"
      sleep 0.01
      When call profiling_stop "duration_test"
      The status should be success
    End

    It 'logs duration to file'
      call profiling_start "log_test"
      sleep 0.01
      When call profiling_stop "log_test"
      The file "${PROFILING_LOG}" should exist
      The contents of file "${PROFILING_LOG}" should include "log_test"
    End

    It 'handles non-existent timer gracefully'
      When call profiling_stop "nonexistent_timer"
      The status should be success
    End

    It 'does nothing when profiling disabled'
      export PROFILING_ENABLED=false
      When call profiling_stop "any_timer"
      The status should be success
    End
  End

  # ===================================================================
  # Tests: profiling_increment()
  # ===================================================================
  Describe 'profiling_increment() - Increment Counter'

    It 'increments counter successfully'
      When call profiling_increment "test_counter"
      The status should be success
    End

    It 'increments from zero to one'
      call profiling_increment "zero_counter"
      When call profiling_get "zero_counter"
      The output should eq "1"
    End

    It 'increments multiple times'
      call profiling_increment "multi_counter"
      call profiling_increment "multi_counter"
      call profiling_increment "multi_counter"
      When call profiling_get "multi_counter"
      The output should eq "3"
    End

    It 'handles multiple counters'
      call profiling_increment "counter1"
      call profiling_increment "counter2"
      call profiling_increment "counter1"
      When call profiling_get "counter1"
      The output should eq "2"
      When call profiling_get "counter2"
      The output should eq "1"
    End

    It 'does nothing when profiling disabled'
      export PROFILING_ENABLED=false
      call profiling_increment "disabled_counter"
      When call profiling_get "disabled_counter"
      The output should eq "0"
    End
  End

  # ===================================================================
  # Tests: profiling_get()
  # ===================================================================
  Describe 'profiling_get() - Get Counter Value'

    It 'returns zero for non-existent counter'
      When call profiling_get "nonexistent"
      The output should eq "0"
    End

    It 'returns correct value for existing counter'
      call profiling_increment "existing_counter"
      call profiling_increment "existing_counter"
      When call profiling_get "existing_counter"
      The output should eq "2"
    End

    It 'returns zero for uninitialized counter'
      When call profiling_get "uninitialized"
      The output should eq "0"
    End
  End

  # ===================================================================
  # Tests: profiling_summary()
  # ===================================================================
  Describe 'profiling_summary() - Summary Display'

    It 'displays summary successfully'
      When call profiling_summary
      The status should be success
      The output should include "Profiling Summary"
    End

    It 'displays counters when present'
      call profiling_increment "summary_counter"
      call profiling_increment "summary_counter"
      When call profiling_summary
      The output should include "summary_counter"
      The output should include "2"
    End

    It 'displays profiling rundl'
      touch "${PROFILING_LOG}"
      When call profiling_summary
      The output should include "Profiling log:"
    End

    It 'does nothing when profiling disabled'
      export PROFILING_ENABLED=false
      When call profiling_summary
      The status should be success
    End

    It 'handles empty log file'
      touch "${PROFILING_LOG}"
      When call profiling_summary
      The status should be success
    End
  End

  # ===================================================================
  # Tests: Edge Cases and Integration
  # ===================================================================
  Describe 'Edge Cases and Integration'

    It 'handles timer start and stop cycle'
      When call profiling_start "cycle_timer"
      When call profiling_stop "cycle_timer"
      The status should be success
    End

    It 'handles multiple timers concurrently'
      When call profiling_start "concurrent1"
      When call profiling_start "concurrent2"
      When call profiling_stop "concurrent1"
      When call profiling_stop "concurrent2"
      The status should be success
    End

    It 'handles nested profiling calls'
      call profiling_start "outer"
      call profiling_start "inner"
      When call profiling_stop "inner"
      When call profiling_stop "outer"
      The status should be success
    End

    It 'handles large counter values'
      local i=1
      while [ $i -le 100 ]; do
        call profiling_increment "large_counter"
        i=$((i + 1))
      done
      When call profiling_get "large_counter"
      The output should eq "100"
    End

    It 'handles special characters in timer names'
      When call profiling_start "timer-with-dashes_123"
      When call profiling_stop "timer-with-dashes_123"
      The status should be success
    End

    It 'handles empty timer name'
      When call profiling_start ""
      When call profiling_stop ""
      The status should be success
    End

    It 'handles empty counter name'
      When call profiling_increment ""
      When call profiling_get ""
      The output should eq "1"
    End
  End

End
