#!/usr/bin/env shellspec
# Tests ShellSpec pour module Config

Describe 'Config Module - Complete Test Suite'

  setup_config() {
    source lib/logging/logger.sh
    source config/config.sh
    export VERBOSE_LEVEL=0
    export QUIET_MODE=false
  }

  Before setup_config

  # ===================================================================
  # Tests: init_config()
  # ===================================================================
  Describe 'init_config() - Configuration Initialization'

    It 'initializes successfully'
      When call init_config
      The status should be success
    End

    It 'sets default values'
      call init_config
      When call get_config
      The status should be success
    End
  End

  # ===================================================================
  # Tests: get_config_module_info()
  # ===================================================================
  Describe 'get_config_module_info() - Module Information'

    It 'displays module information'
      When call get_config_module_info
      The output should include "Module: git_mirror_config"
    End
  End

End

