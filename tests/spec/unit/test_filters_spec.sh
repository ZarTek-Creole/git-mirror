#!/usr/bin/env shellspec
# Tests ShellSpec pour module Filters

Describe 'Filters Module'

  setup_filters() {
    source lib/logging/logger.sh
    source lib/filters/filters.sh
    export VERBOSE_LEVEL=0
    export QUIET_MODE=false
  }

  Before setup_filters

  # ===================================================================
  # Tests: Initialization
  # ===================================================================
  Describe 'Module Initialization'

    It 'initializes filters module'
      When call init_filters
      The status should be success
    End
  End

  # ===================================================================
  # Tests: Filtering Logic
  # ===================================================================
  Describe 'Pattern Matching'

    It 'matches simple pattern'
      local pattern="test-*"
      local repo="test-repo"
      When call should_include_repo "$repo" "$pattern"
      The status should be success
    End

    It 'rejects non-matching pattern'
      local pattern="test-*"
      local repo="other-repo"
      When call should_include_repo "$repo" "$pattern"
      The status should be failure
    End
  End

End

