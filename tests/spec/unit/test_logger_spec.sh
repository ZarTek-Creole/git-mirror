#!/usr/bin/env shellspec
# Tests ShellSpec pour module Logger

Describe 'Logger Module'

  setup_logger() {
    source lib/logging/logger.sh
    export VERBOSE_LEVEL=0
    export QUIET_MODE=false
    export DRY_RUN_MODE=false
  }

  Before setup_logger

  Describe 'init_logger()'
    It 'initializes with defaults'
      When call init_logger
      The status should be success
    End
  End

  Describe 'log_error()'
    It 'logs error message'
      When call log_error "Test error"
      The status should be success
      The output should include "ERROR"
    End
  End

End
