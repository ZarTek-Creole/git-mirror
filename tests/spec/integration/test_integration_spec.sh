#!/usr/bin/env shellspec
# Tests d'intégration ShellSpec - End-to-End

Describe 'Integration Tests - Complete Workflow'

  setup_integration() {
    source lib/logging/logger.sh
    source lib/validation/validation.sh
    source lib/config/config.sh
    export VERBOSE_LEVEL=0
    export QUIET_MODE=false
    export DRY_RUN=false
  }

  Before setup_integration

  # ===================================================================
  # Tests: End-to-End Workflow
  # ===================================================================
  Describe 'End-to-End Integration - Complete Workflow'

    It 'validates complete parameter set'
      When call validate_all_params "users" "testuser" "./repos" "main" "" "1" "1" "30"
      The status should be success
    End

    It 'rejects invalid parameters'
      When call validate_all_params "invalid" "testuser" "./repos" "main" "" "1" "1" "30"
      The status should be failure
    End

    It 'validates context correctly'
      When call validate_context "users"
      The status should be success
      When call validate_context "orgs"
      The status should be success
      When call validate_context "invalid"
      The status should be failure
    End

    It 'validates username with patterns'
      When call validate_username "testuser"
      The status should be success
      When call validate_username "test-user"
      The status should be success
      When call validate_username "test_user"
      The status should be failure
    End
  End

  # ===================================================================
  # Tests: Module Interactions
  # ===================================================================
  Describe 'Module Interactions - Cross-Module'

    It 'initializes validation module'
      When call validate_setup
      The status should be success
    End

    It 'initializes logger module'
      When call init_logger "0" "false" "false" "true"
      The status should be success
    End
  End

End

