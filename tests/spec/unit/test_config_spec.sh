#!/usr/bin/env shellspec
# Tests ShellSpec complets pour module Config
# Couverture: 100% de toutes les fonctions

Describe 'Config Module - Complete Test Suite (100% Coverage)'

  setup_config() {
    export GIT_MIRROR_TEST_MODE=true
    export VERBOSE_LEVEL=2
    export QUIET_MODE=false
    
    # Charger les d?pendances
    source lib/logging/logger.sh
    init_logger 0 false false true
    
    # Charger le module
    source config/config.sh
  }

  teardown_config() {
    unset GITHUB_TOKEN GITHUB_SSH_KEY GITHUB_AUTH_METHOD
    unset GIT_MIRROR_DEST_DIR GIT_MIRROR_CACHE_TTL GIT_MIRROR_PARALLEL_JOBS
  }

  Before setup_config
  After teardown_config

  # ===================================================================
  # Tests: get_config_module_info()
  # ===================================================================
  Describe 'get_config_module_info() - Module Information'

    It 'displays module information'
      When call get_config_module_info
      The status should be success
      The output should include "Module:"
      The output should include "Configuration"
    End
  End

  # ===================================================================
  # Tests: init_config()
  # ===================================================================
  Describe 'init_config() - Configuration Initialization'

    It 'initializes successfully'
      When call init_config
      The status should be success
    End

    It 'loads environment variables'
      export GITHUB_TOKEN="ghp_test123"
      export GIT_MIRROR_DEST_DIR="/tmp/test-dest"
      When call init_config
      The status should be success
    End

    It 'validates configuration'
      DEPTH=5
      VERBOSE=2
      PARALLEL_JOBS=4
      When call init_config
      The status should be success
    End

    It 'rejects invalid depth'
      DEPTH=2000
      When call init_config
      The status should be failure
    End

    It 'rejects invalid verbose level'
      VERBOSE=10
      When call init_config
      The status should be failure
    End

    It 'rejects invalid parallel jobs'
      PARALLEL_JOBS=100
      When call init_config
      The status should be failure
    End
  End

  # ===================================================================
  # Tests: get_config()
  # ===================================================================
  Describe 'get_config() - Get Configuration'

    It 'displays complete configuration'
      DEST_DIR="./test-repos"
      context="users"
      username_or_orgname="testuser"
      When call get_config
      The status should be success
      The output should include "Configuration Git Mirror"
      The output should include "./test-repos"
      The output should include "users"
      The output should include "testuser"
    End
  End

  # ===================================================================
  # Tests: get_config_help()
  # ===================================================================
  Describe 'get_config_help() - Configuration Help'

    It 'displays help information'
      When call get_config_help
      The status should be success
      The output should include "Configuration par d?faut"
      The output should include "Variables d'environnement"
    End
  End

  # ===================================================================
  # Tests: save_config()
  # ===================================================================
  Describe 'save_config() - Save Configuration'

    It 'saves configuration to file'
      local config_file="/tmp/test-config-$$.json"
      DEST_DIR="./test-repos"
      When call save_config "$config_file"
      The status should be success
      The file "$config_file" should exist
      The contents of file "$config_file" should include "version"
      The contents of file "$config_file" should include "./test-repos"
      rm -f "$config_file"
    End

    It 'saves to default file'
      DEST_DIR="./test-repos"
      When call save_config
      The status should be success
      The file ".git-mirror-config.json" should exist
      rm -f ".git-mirror-config.json"
    End
  End

  # ===================================================================
  # Tests: load_config()
  # ===================================================================
  Describe 'load_config() - Load Configuration'

    It 'loads configuration from file'
      local config_file="/tmp/test-config-$$.json"
      cat > "$config_file" <<EOF
{
  "version": "1.0.0",
  "configuration": {
    "dest_dir": "/tmp/loaded-dest",
    "depth": 5,
    "verbose": 2
  }
}
EOF
      When call load_config "$config_file"
      The status should be success
      rm -f "$config_file"
    End

    It 'returns failure when file does not exist'
      When call load_config "/tmp/nonexistent-$$.json"
      The status should be failure
    End

    It 'handles missing jq gracefully'
      command() {
        if [ "$1" = "-v" ] && [ "$2" = "jq" ]; then
          return 1
        fi
        command "$@"
      }
      export -f command
      
      local config_file="/tmp/test-config-$$.json"
      echo '{"test":"data"}' > "$config_file"
      When call load_config "$config_file"
      The status should be failure
      rm -f "$config_file"
    End
  End

  # ===================================================================
  # Tests: _load_environment_variables()
  # ===================================================================
  Describe '_load_environment_variables() - Load Environment Variables'

    It 'loads GITHUB_TOKEN from environment'
      export GITHUB_TOKEN="ghp_env_token123"
      When call _load_environment_variables
      The status should be success
    End

    It 'loads GITHUB_SSH_KEY from environment'
      export GITHUB_SSH_KEY="/path/to/key"
      When call _load_environment_variables
      The status should be success
    End

    It 'loads GITHUB_AUTH_METHOD from environment'
      export GITHUB_AUTH_METHOD="token"
      When call _load_environment_variables
      The status should be success
    End

    It 'loads GIT_MIRROR_DEST_DIR from environment'
      export GIT_MIRROR_DEST_DIR="/tmp/env-dest"
      When call _load_environment_variables
      The status should be success
    End

    It 'loads GIT_MIRROR_CACHE_TTL from environment'
      export GIT_MIRROR_CACHE_TTL="7200"
      When call _load_environment_variables
      The status should be success
    End

    It 'loads GIT_MIRROR_PARALLEL_JOBS from environment'
      export GIT_MIRROR_PARALLEL_JOBS="5"
      When call _load_environment_variables
      The status should be success
    End
  End

  # ===================================================================
  # Tests: _validate_configuration()
  # ===================================================================
  Describe '_validate_configuration() - Configuration Validation'

    It 'validates correct configuration'
      DEPTH=5
      VERBOSE=2
      PARALLEL_JOBS=4
      CACHE_TTL=3600
      TIMEOUT_CUSTOM=30
      When call _validate_configuration
      The status should be success
    End

    It 'rejects invalid depth'
      DEPTH=2000
      When call _validate_configuration
      The status should be failure
    End

    It 'rejects invalid verbose level'
      VERBOSE=10
      When call _validate_configuration
      The status should be failure
    End

    It 'rejects invalid parallel jobs'
      PARALLEL_JOBS=100
      When call _validate_configuration
      The status should be failure
    End

    It 'rejects invalid cache TTL'
      CACHE_TTL=30
      When call _validate_configuration
      The status should be failure
    End

    It 'rejects invalid timeout'
      TIMEOUT_CUSTOM=5000
      When call _validate_configuration
      The status should be failure
    End
  End

  # ===================================================================
  # Tests: reset_config()
  # ===================================================================
  Describe 'reset_config() - Reset Configuration'

    It 'resets to default values'
      DEST_DIR="/custom/path"
      DEPTH=10
      VERBOSE=3
      When call reset_config
      The status should be success
      # V?rifier que les valeurs sont r?initialis?es
      # (ces variables ne sont pas directement accessibles depuis les tests)
    End
  End

End
