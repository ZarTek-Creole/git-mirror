#!/usr/bin/env shell独立
# Tests ShellSpec pour module Logger

Describe 'Logger Module - Complete Test Suite'

  setup_logger() {
    export VERBOSE_LEVEL=0
    export QUIET_MODE=false
    export DRY_RUN_MODE=false
    export LOG_TIMESTAMP=true
    set +u
    source lib/logging/logger.sh
    set -u
  }

  teardown_logger() {
    unset VERBOSE_LEVEL QUIET_MODE DRY_RUN_MODE LOG_TIMESTAMP
  }

  Before setup_logger
  After teardown_logger

  Describe 'init_logger() - Module Initialization'

    It 'initializes with default values'
      When call init_logger
      The status should be success
    End

    It 'initializes with verbose level 2'
      When call init_logger 2 false false true
      The status should be success
    End

    It 'initializes with quiet mode enabled'
      When call init_logger 0 true false true
      The status should be success
    End

    It 'initializes with dry-run mode enabled'
      When call init_logger 0 false true true
      The status should be success
    End

    It 'initializes with no timestamp'
      When call init_logger 0 false false false
      The status should be success
    End

    It 'rejects invalid verbose_level'
      When call init_logger "invalid" false false true
      The status should be failure
      The error should include "verbose_level doit être un nombre"
    End

    It 'rejects invalid quiet_mode'
      When call init_logger 0 "invalid" false true
      The status should be failure
      The error should include "quiet_mode doit être"
    End

    It 'rejects invalid dry_run_mode'
      When call init_logger 0 false "invalid" true
      The status should be failure
      The error should include "dry_run_mode doit être"
    End

    It 'rejects invalid timestamp'
      When call init_logger 0 false false "invalid"
      The status should be failure
      The error should include "timestamp doit être"
    End
  End

  Describe 'log_error() - Error Logging'

    It 'logs error message with ERROR tag'
      When call log_error "Test error message"
      The status should be success
      The output should include "ERROR"
      The output should include "Test error message"
    End

    It 'logs error message in quiet mode'
      export QUIET_MODE=false
      When call log_error "Error in quiet mode"
      The output should include "ERROR"
    End

    It 'does not log when quiet mode is true'
      export QUIET_MODE=true
      When call log_error "Hidden error"
      The output should be empty
      The status should be success
    End
  End

  Describe 'log_warning() - Warning Logging'

    It 'logs warning message'
      When call log_warning "Test warning"
      The status should be success
      The output should include "WARNING"
      The output should include "Test warning"
    End

    It 'does not log when quiet mode is true'
      export QUIET_MODE=true
      When call log_warning "Hidden warning"
      The output should be empty
    End
  End

  Describe 'log_info() - Info Logging'

    It 'logs info message'
      When call log_info "Test info"
      The status should be success
      The output should include "INFO"
      The output should include "Test info"
    End

    It 'does not log when quiet mode is true'
      export QUIET_MODE=true
      When call log_info "Hidden info"
      The output should be empty
    End
  End

  Describe 'log_success() - Success Logging'

    It 'logs success message'
      When call log_success "Operation succeeded"
      The status should be success
      The output should include "SUCCESS"
      The output should include "Operation succeeded"
    End

    It 'does not log when quiet mode is true'
      export QUIET_MODE=true
      When call log_success "Hidden success"
      The output should be empty
    End
  End

  Describe 'log_debug() - Debug Logging'

    It 'does not log at verbose level 0'
      When call log_debug "Debug at level 0"
      The output should be empty
      The status should be success
    End

    It 'logs at verbose level 2'
      export VERBOSE_LEVEL=2
      When call log_debug "Debug at level 2"
      The status should be success
      The output should include "DEBUG"
      The output should include "Debug at level 2"
    End

    It 'logs at verbose level 3'
      export VERBOSE_LEVEL=3
      When call log_debug "Debug at level 3"
      The output should include "DEBUG"
    End

    It 'does not log when quiet mode is true'
      export VERBOSE_LEVEL=2
      export QUIET_MODE=true
      When call log_debug "Hidden debug"
      The output should be empty
    End
  End

  Describe 'log_trace() - Trace Logging'

    It 'does not log at verbose level 0'
      When call log_trace "Trace message"
      The output should be empty
    End

    It 'does not log at verbose level 2'
      export VERBOSE_LEVEL=2
      When call log_trace "Trace at level 2"
      The output should be empty
    End

    It 'logs at verbose level 3'
      export VERBOSE_LEVEL=3
      When call log_trace "Trace at level 3"
      The output should include "TRACE"
      The output should include "Trace at level 3"
    End
  End

  Describe 'log_dry_run() - Dry-run Logging'

    It 'does not log when dry-run mode is false'
      When call log_dry_run "Dry-run message"
      The output should be empty
    End

    It 'logs when dry-run mode is true'
      export DRY_RUN_MODE=true
      When call log_dry_run "Dry-run operation"
      The output should include "DRY-RUN"
      The output should include "Dry-run operation"
    End

    It 'does not log when quiet mode is true'
      export DRY_RUN_MODE=true
      export QUIET_MODE=true
      When call log_dry_run "Hidden dry-run"
      The output should be empty
    End
  End

  Describe 'error() - Fatal Error Function'

    It 'logs error and exits with code 1'
      When run error "Fatal error"
      The output should include "ERROR"
      The output should include "Fatal error"
      The status should be failure
    End

    It 'logs error and exits with custom code'
      When run error "Custom error" 42
      The output should include "ERROR"
      The status should eq 42
    End
  End

  Describe 'warn() - Warning Function'

    It 'logs warning message'
      When call warn "Warning via warn()"
      The status should be success
      The output should include "WARNING"
      The output should include "Warning via warn()"
    End
  End

  Describe 'logger_status() - Module Status'

    It 'displays logger status'
      When call logger_status
      The status should be success
      The output should include "Logger Module Status"
      The output should include "Version"
      The output should include "Verbose Level"
      The output should include "Quiet Mode"
      The output should include "Dry-run Mode"
      The output should include "Timestamp"
    End
  End

  Describe 'Edge Cases'

    It 'handles empty message'
      When call log_info ""
      The status should be success
      The output should include "INFO"
    End

    It 'handles message with special characters'
      When call log_info "Message with \$pecial chars & <tags>"
      The status should be success
      The output should include "INFO"
      The output should include "Message with"
    End

    It 'validates timestamp behavior'
      export LOG_TIMESTAMP=true
      When call log_info "With timestamp"
      The output should match pattern '*[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]*'
    End

    It 'omits timestamp when disabled'
      export LOG_TIMESTAMP=false
      When call log_info "Without timestamp"
      The output should include "INFO"
      The output should not match pattern '*[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]*'
    End
  End

End
