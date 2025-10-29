#!/usr/bin/env shellspec
# Tests ShellSpec pour module Interactive

Describe 'Interactive Module - Complete Test Suite'

  setup_interactive() {
    source lib/logging/logger.sh
    source lib/interactive/interactive.sh
    export VERBOSE_LEVEL=0
    export QUIET_MODE=false
    export AUTO_YES=true  # Pour éviter les prompts interactifs
  }

  Before setup_interactive

  # ===================================================================
  # Tests: interactive_setup()
  # ===================================================================
  Describe 'interactive_setup() - Module Setup'

    It 'initializes successfully'
      When call interactive_setup
      The status should be success
    End
  End

  # ===================================================================
  # Tests: interactive_confirm_start()
  # ===================================================================
  Describe 'interactive_confirm_start() - Start Confirmation'

    It 'proceeds with auto_yes enabled'
      export AUTO_YES=true
      When call interactive_confirm_start "users" "testuser" "./repos" "100" "500" "1" "false" "false" "public"
      The status should be success
    End
  End

End

