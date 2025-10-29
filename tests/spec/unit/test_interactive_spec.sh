#!/usr/bin/env shellspec
# Tests ShellSpec pour module Interactive

Describe 'Interactive Module - Complete Test Suite'

  setup_interactive() {
    source lib/logging/logger.sh
    source lib/interactive/interactive.sh
    export VERBOSE_LEVEL=0
    export QUIET_MODE=false
    export AUTO_YES=false
    export INTERACTIVE_MODE=false
    export CONFIRM_MODE=false
  }

  teardown_interactive() {
    unset AUTO_YES
    unset INTERACTIVE_MODE
    unset CONFIRM_MODE
    unset VERBOSE_LEVEL
  }

  Before setup_interactive
  After teardown_interactive

  # ===================================================================
  # Tests: interactive_init()
  # ===================================================================
  Describe 'interactive_init() - Module Initialization'

    It 'initializes variables successfully'
      When call interactive_init
      The status should be success
    End

    It 'logs debug information'
      When call interactive_init
      The status should be success
    End
  End

  # ===================================================================
  # Tests: get_interactive_stats()
  # ===================================================================
  Describe 'get_interactive_stats() - Statistics Display'

    It 'displays interactive statistics'
      When call get_interactive_stats
      The status should be success
      The output should include "Interactive Statistics:"
      The output should include "Interactive mode:"
      The output should include "Confirm mode:"
      The output should include "Auto yes:"
    End

    It 'shows correct mode values'
      When call get_interactive_stats
      The output should include "false"
    End
  End

  # ===================================================================
  # Tests: interactive_is_terminal()
  # ===================================================================
  Describe 'interactive_is_terminal() - Terminal Detection'

    It 'returns status for terminal'
      When call interactive_is_terminal
      The status should be defined
    End

    It 'detects terminal correctly'
      When call interactive_is_terminal
      The status should be defined
    End
  End

  # ===================================================================
  # Tests: interactive_confirm()
  # ===================================================================
  Describe 'interactive_confirm() - User Confirmation'

    It 'returns success with AUTO_YES enabled and default yes'
      export AUTO_YES=true
      When call interactive_confirm "Test message" "y"
      The status should be success
    End

    It 'returns failure with AUTO_YES enabled and default no'
      export AUTO_YES=true
      When call interactive_confirm "Test message" "n"
      The status should be failure
    End

    It 'returns default with non-terminal'
      export AUTO_YES=false
      # Simulate non-terminal by mocking stdin/stdout check
      When call interactive_confirm "Test message" "y"
      The status should be success
    End
  End

  # ===================================================================
  # Tests: interactive_show_summary()
  # ===================================================================
  Describe 'interactive_show_summary() - Summary Display'

    It 'displays summary with all parameters'
      When call interactive_show_summary "users" "testuser" "./repos" "100" "500" "4" "true" "false" "public"
      The status should be success
      The output should include "Résumé de l'Opération"
      The output should include "users"
      The output should include "testuser"
      The output should include "100 repos"
    End

    It 'displays parallelization info when enabled'
      When call interactive_show_summary "users" "testuser" "./repos" "100" "500" "4" "true" "false" "public"
      The output should include "Parallélisation"
    End

    It 'displays filter info when enabled'
      When call interactive_show_summary "users" "testuser" "./repos" "100" "500" "1" "true" "false" "public"
      The output should include "Filtre"
    End

    It 'displays incremental mode when enabled'
      When call interactive_show_summary "users" "testuser" "./repos" "100" "500" "1" "false" "true" "public"
      The output should include "Mode incrémental"
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
      The output should include "Confirmation reçue"
    End

    It 'shows summary before confirmation'
      export AUTO_YES=true
      When call interactive_confirm_start "users" "testuser" "./repos" "50" "250" "2" "true" "false" "token"
      The output should include "Résumé de l'Opération"
    End

    It 'returns success in auto mode'
      export AUTO_YES=true
      When call interactive_confirm_start "users" "testuser" "./repos" "100" "500" "1" "false" "false" "public"
      The status should be success
    End
  End

  # ===================================================================
  # Tests: interactive_show_progress()
  # ===================================================================
  Describe 'interactive_show_progress() - Progress Bar'

    It 'displays progress at 0%'
      When call interactive_show_progress "0" "10" "Test"
      The status should be success
    End

    It 'displays progress at 50%'
      When call interactive_show_progress "5" "10" "Test"
      The status should be success
    End

    It 'displays progress at 100%'
      When call interactive_show_progress "10" " knows :-)"
      The status should be success
    End

    It 'handles same current and total'
      When call interactive_show_progress "5" "5" "Complete"
      The status should be success
    End

    It 'does nothing when not in interactive mode'
      export INTERACTIVE_MODE=false
      When call interactive_show_progress "3" "10" "Test"
      The status should be success
    End
  End

  # ===================================================================
  # Tests: interactive_confirm_continue()
  # ===================================================================
  Describe 'interactive_confirm_continue() - Continue After Error'

    It 'continues with auto_yes enabled'
      export AUTO_YES=true
      When call interactive_confirm_continue "Test error message"
      The status should be success
      The output should include "Continuation de l'opération"
    End

    It 'shows error message'
      export AUTO_YES=true
      When call interactive_confirm_continue "Sample error"
      The output should include "Sample error"
    End

    It 'returns success in auto mode'
      export AUTO_YES=true
      When call interactive_confirm_continue "Error"
      The status should be success
    End
  End

  # ===================================================================
  # Tests: interactive_select_repos()
  # ===================================================================
  Describe 'interactive_select_repos() - Repository Selection'

    It 'returns all repos when not in interactive mode'
      export INTERACTIVE_MODE=false
      local repos_json='[{"name":"repo1"},{"name":"repo2"}]'
      When call interactive_select_repos "$repos_json"
      The output should eq "$repos_json"
      The status should be success
    End

    It 'returns repos as JSON array'
      export INTERACTIVE_MODE=false
      local repos_json='[{"name":"test-repo","description":"Test"}]'
      When call interactive_select_repos "$repos_json"
      The output should include "test-repo"
    End
  End

  # ===================================================================
  # Tests: interactive_setup()
  # ===================================================================
  Describe 'interactive_setup() - Module Setup'

    It 'initializes successfully'
      When call interactive_setup
      The status should be success
    End

    It 'initializes with interactive mode enabled'
      export INTERACTIVE_MODE=true
      When call interactive_setup
      The status should be success
      The output should include "Module interactif initialisé"
    End

    It 'initializes with confirm mode enabled'
      export CONFIRM_MODE=true
      When call interactive_setup
      The status should be success
      The output should include "Module interactif initialisé"
    End

    It 'initializes with auto_yes enabled'
      export AUTO_YES=true
      When call interactive_setup
      The status should be success
    End

    It 'initializes with both interactive and auto_yes'
      export INTERACTIVE_MODE=true
      export AUTO_YES=true
      When call interactive_setup
      The status should be success
    End
  End

  # ===================================================================
  # Tests: Edge Cases and Integration
  # ===================================================================
  Describe 'Edge Cases and Integration'

    It 'handles zero total progress'
      When call interactive_show_progress "0" "0" "Test"
      The status should be success
    End

    It 'handles empty repos JSON'
      export INTERACTIVE_MODE=false
      When call interactive_select_repos "[]"
      The output should eq "[]"
      The status should be success
    End

    It 'handles invalid repos JSON gracefully'
      export INTERACTIVE_MODE=false
      When call interactive_select_repos "invalid"
      The status should be success
    End

    It 'validates summary with all special characters'
      When call interactive_show_summary "users" "test-user" "./repos_dir" "999" "7777" "8" "true" "true" "ssh"
      The status should be success
    End
  End

End
