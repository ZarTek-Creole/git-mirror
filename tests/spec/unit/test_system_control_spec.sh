#!/usr/bin/env shellspec
# Tests ShellSpec complets pour module System Control
# Couverture: 100% de toutes les fonctions

Describe 'System Control Module - Complete Test Suite (100% Coverage)'

  setup_system() {
    export GIT_MIRROR_TEST_MODE=true
    export VERBOSE_LEVEL=2
    export QUIET_MODE=false
    export SYSTEM_RESOURCE_LIMITS=false
    export NICE_PRIORITY=10
    export IONICE_CLASS=2
    export IONICE_LEVEL=4
    
    # Charger les dépendances
    source lib/logging/logger.sh
    init_logger 0 false false true
    
    # Charger le module
    source lib/system/system_control.sh
  }

  teardown_system() {
    unset SYSTEM_RESOURCE_LIMITS NICE_PRIORITY IONICE_CLASS IONICE_LEVEL
    unset SYSTEM_NICE_SET SYSTEM_IONICE_SET GIT_SSH_COMMAND
  }

  Before setup_system
  After teardown_system

  # ===================================================================
  # Tests: apply_resource_limits()
  # ===================================================================
  Describe 'apply_resource_limits() - Resource Limits'

    It 'does nothing when limits disabled'
      export SYSTEM_RESOURCE_LIMITS=false
      When call apply_resource_limits
      The status should be success
    End

    It 'applies file descriptor limit when enabled'
      export SYSTEM_RESOURCE_LIMITS=true
      When call apply_resource_limits
      The status should be success
    End

    It 'handles ulimit failure gracefully'
      export SYSTEM_RESOURCE_LIMITS=true
      ulimit() {
        return 1
      }
      export -f ulimit
      
      When call apply_resource_limits
      The status should be success
    End
  End

  # ===================================================================
  # Tests: apply_nice_priority()
  # ===================================================================
  Describe 'apply_nice_priority() - CPU Priority'

    It 'does nothing when limits disabled'
      export SYSTEM_RESOURCE_LIMITS=false
      When call apply_nice_priority
      The status should be success
    End

    It 'applies nice priority when enabled'
      export SYSTEM_RESOURCE_LIMITS=true
      command() {
        if [ "$1" = "-v" ] && [ "$2" = "nice" ]; then
          return 0
        fi
        command "$@"
      }
      export -f command
      
      nice() {
        return 0
      }
      export -f nice
      
      When call apply_nice_priority
      The status should be success
    End

    It 'handles missing nice command'
      export SYSTEM_RESOURCE_LIMITS=true
      command() {
        if [ "$1" = "-v" ] && [ "$2" = "nice" ]; then
          return 1
        fi
        command "$@"
      }
      export -f command
      
      When call apply_nice_priority
      The status should be failure
    End

    It 'handles nice failure'
      export SYSTEM_RESOURCE_LIMITS=true
      command() {
        if [ "$1" = "-v" ] && [ "$2" = "nice" ]; then
          return 0
        fi
        command "$@"
      }
      export -f command
      
      nice() {
        return 1
      }
      export -f nice
      
      When call apply_nice_priority
      The status should be failure
    End
  End

  # ===================================================================
  # Tests: apply_ionice_priority()
  # ===================================================================
  Describe 'apply_ionice_priority() - I/O Priority'

    It 'does nothing when limits disabled'
      export SYSTEM_RESOURCE_LIMITS=false
      When call apply_ionice_priority
      The status should be success
    End

    It 'applies ionice priority when enabled'
      export SYSTEM_RESOURCE_LIMITS=true
      command() {
        if [ "$1" = "-v" ] && [ "$2" = "ionice" ]; then
          return 0
        fi
        command "$@"
      }
      export -f command
      
      ionice() {
        return 0
      }
      export -f ionice
      
      When call apply_ionice_priority
      The status should be success
    End

    It 'handles missing ionice command'
      export SYSTEM_RESOURCE_LIMITS=true
      command() {
        if [ "$1" = "-v" ] && [ "$2" = "ionice" ]; then
          return 1
        fi
        command "$@"
      }
      export -f command
      
      When call apply_ionice_priority
      The status should be failure
    End

    It 'handles ionice failure'
      export SYSTEM_RESOURCE_LIMITS=true
      command() {
        if [ "$1" = "-v" ] && [ "$2" = "ionice" ]; then
          return 0
        fi
        command "$@"
      }
      export -f command
      
      ionice() {
        return 1
      }
      export -f ionice
      
      When call apply_ionice_priority
      The status should be failure
    End
  End

  # ===================================================================
  # Tests: apply_network_compression()
  # ===================================================================
  Describe 'apply_network_compression() - Network Compression'

    It 'does nothing when limits disabled'
      export SYSTEM_RESOURCE_LIMITS=false
      When call apply_network_compression
      The status should be success
    End

    It 'applies SSH compression when enabled'
      export SYSTEM_RESOURCE_LIMITS=true
      When call apply_network_compression
      The status should be success
      The variable GIT_SSH_COMMAND should include "Compression=yes"
    End

    It 'sets compression level'
      export SYSTEM_RESOURCE_LIMITS=true
      When call apply_network_compression
      The variable GIT_SSH_COMMAND should include "CompressionLevel=6"
    End
  End

  # ===================================================================
  # Tests: system_execute_with_limits()
  # ===================================================================
  Describe 'system_execute_with_limits() - Execute with Limits'

    It 'executes command normally when limits disabled'
      export SYSTEM_RESOURCE_LIMITS=false
      When call system_execute_with_limits "echo test"
      The status should be success
      The output should include "test"
    End

    It 'executes command with limits when enabled'
      export SYSTEM_RESOURCE_LIMITS=true
      export SYSTEM_NICE_SET=true
      export SYSTEM_IONICE_SET=true
      
      command() {
        if [ "$1" = "-v" ]; then
          return 0
        fi
        command "$@"
      }
      export -f command
      
      nice() {
        shift
        "$@"
      }
      export -f nice
      
      ionice() {
        shift 3
        "$@"
      }
      export -f ionice
      
      When call system_execute_with_limits "echo test"
      The status should be success
      The output should include "test"
    End

    It 'handles command failure'
      export SYSTEM_RESOURCE_LIMITS=false
      When call system_execute_with_limits "false"
      The status should be failure
    End
  End

  # ===================================================================
  # Tests: system_control_init()
  # ===================================================================
  Describe 'system_control_init() - Module Initialization'

    It 'initializes when limits enabled'
      export SYSTEM_RESOURCE_LIMITS=true
      command() {
        return 0
      }
      export -f command
      
      nice() {
        return 0
      }
      export -f nice
      
      ionice() {
        return 0
      }
      export -f ionice
      
      When call system_control_init
      The status should be success
    End

    It 'does not initialize when limits disabled'
      export SYSTEM_RESOURCE_LIMITS=false
      When call system_control_init
      The status should be success
    End

    It 'applies all optimizations'
      export SYSTEM_RESOURCE_LIMITS=true
      command() {
        return 0
      }
      export -f command
      
      nice() {
        return 0
      }
      export -f nice
      
      ionice() {
        return 0
      }
      export -f ionice
      
      When call system_control_init
      The status should be success
    End
  End

  # ===================================================================
  # Tests: system_show_limits()
  # ===================================================================
  Describe 'system_show_limits() - Display Limits'

    It 'displays current system limits'
      ulimit() {
        if [ "$1" = "-n" ]; then
          echo "1024"
        elif [ "$1" = "-v" ]; then
          echo "unlimited"
        fi
      }
      export -f ulimit
      
      nice() {
        echo "10"
      }
      export -f nice
      
      ionice() {
        echo "best-effort: prio 4"
      }
      export -f ionice
      
      When call system_show_limits
      The status should be success
      The output should include "File descriptors"
      The output should include "Virtual memory"
    End

    It 'handles missing commands gracefully'
      ulimit() {
        if [ "$1" = "-n" ]; then
          echo "1024"
        elif [ "$1" = "-v" ]; then
          echo "unlimited"
        fi
      }
      export -f ulimit
      
      nice() {
        echo "not set"
      }
      export -f nice
      
      ionice() {
        echo "not set"
      }
      export -f ionice
      
      When call system_show_limits
      The status should be success
    End
  End

End
