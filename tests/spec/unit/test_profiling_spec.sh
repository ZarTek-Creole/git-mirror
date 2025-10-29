#!/usr/bin/env shellspec
# Tests ShellSpec pour module Profiling

Describe 'Profiling Module - Complete Test Suite'

  setup_profiling() {
    source lib/logging/logger.sh
    source lib/utils/profiling.sh
    export VERBOSE_LEVEL=0
    export QUIET_MODE=false
    export PROFILING_ENABLED=false  # Désactiver pour tests
  }

  Before setup_profiling

  # ===================================================================
  # Tests: profiling_enable() / profiling_disable()
  # ===================================================================
  Describe 'profiling_enable() / profiling_disable()'

    It 'enables profiling'
      When call profiling_enable
      The status should be success
    End

    It 'disables profiling'
      When call profiling_disable
      The status should be success
    End
  End

  # ===================================================================
  # Tests: profiling_summary()
  # ===================================================================
  Describe 'profiling_summary() - Profiling Summary'

    It 'displays summary'
      When call profiling_summary
      The status should be success
    End
  End

End

