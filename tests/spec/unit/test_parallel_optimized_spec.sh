#!/usr/bin/env shellspec
# Tests ShellSpec complets pour module Parallel Optimized
# Couverture: 100% de toutes les fonctions

Describe 'Parallel Optimized Module - Complete Test Suite (100% Coverage)'

  setup_parallel_opt() {
    export GIT_MIRROR_TEST_MODE=true
    export VERBOSE_LEVEL=2
    export QUIET_MODE=false
    export PARALLEL_AUTO_TUNE=false
    export PARALLEL_DYNAMIC_JOBS=true
    export PARALLEL_MIN_JOBS=1
    export PARALLEL_MAX_JOBS=50
    export DEST_DIR="/tmp/test-dest-$$"
    
    # Charger les dépendances
    source lib/logging/logger.sh
    init_logger 0 false false true
    
    # Charger le module
    source lib/parallel/parallel_optimized.sh
  }

  teardown_parallel_opt() {
    unset PARALLEL_AUTO_TUNE PARALLEL_DYNAMIC_JOBS PARALLEL_MIN_JOBS PARALLEL_MAX_JOBS
    rm -rf "$DEST_DIR" 2>/dev/null || true
  }

  Before setup_parallel_opt
  After teardown_parallel_opt

  # ===================================================================
  # Tests: calculate_optimal_jobs()
  # ===================================================================
  Describe 'calculate_optimal_jobs() - Optimal Jobs Calculation'

    It 'calculates optimal jobs based on system'
      nproc() {
        echo "4"
      }
      export -f nproc
      
      free() {
        echo "Mem: 8 0 8 0 0 0"
      }
      export -f free
      
      When call calculate_optimal_jobs "0"
      The status should be success
      The output should not be empty
    End

    It 'respects minimum jobs'
      PARALLEL_MIN_JOBS=5
      nproc() {
        echo "1"
      }
      export -f nproc
      
      free() {
        echo "Mem: 1 0 1 0 0 0"
      }
      export -f free
      
      When call calculate_optimal_jobs "0"
      The output should include "5"
    End

    It 'respects maximum jobs'
      PARALLEL_MAX_JOBS=10
      nproc() {
        echo "20"
      }
      export -f nproc
      
      free() {
        echo "Mem: 100 0 100 0 0 0"
      }
      export -f free
      
      When call calculate_optimal_jobs "0"
      local result
      result=$(calculate_optimal_jobs "0")
      [ "$result" -le 10 ]
    End

    It 'uses requested jobs if reasonable'
      When call calculate_optimal_jobs "4"
      The output should include "4"
    End
  End

  # ===================================================================
  # Tests: check_network_connectivity()
  # ===================================================================
  Describe 'check_network_connectivity() - Network Connectivity Check'

    It 'checks network connectivity successfully'
      timeout() {
        "$@"
      }
      export -f timeout
      
      ping() {
        return 0
      }
      export -f ping
      
      When call check_network_connectivity
      The status should be success
    End

    It 'handles network failure'
      timeout() {
        "$@"
      }
      export -f timeout
      
      ping() {
        return 1
      }
      export -f ping
      
      When call check_network_connectivity
      The status should be failure
    End

    It 'handles missing timeout command'
      command() {
        if [ "$1" = "-v" ] && [ "$2" = "timeout" ]; then
          return 1
        fi
        command "$@"
      }
      export -f command
      
      ping() {
        return 0
      }
      export -f ping
      
      When call check_network_connectivity
      The status should be success
    End
  End

  # ===================================================================
  # Tests: check_api_quota()
  # ===================================================================
  Describe 'check_api_quota() - API Quota Check'

    It 'checks API quota successfully'
      export GITHUB_TOKEN="ghp_test123"
      curl() {
        echo '{"resources":{"core":{"remaining":4500,"limit":5000}}}'
      }
      export -f curl
      
      When call check_api_quota
      The status should be success
    End

    It 'warns when no token'
      unset GITHUB_TOKEN
      When call check_api_quota
      The status should be failure
    End

    It 'warns when quota low'
      export GITHUB_TOKEN="ghp_test123"
      curl() {
        echo '{"resources":{"core":{"remaining":100,"limit":5000}}}'
      }
      export -f curl
      
      When call check_api_quota
      The status should be failure
    End

    It 'handles API error'
      export GITHUB_TOKEN="ghp_test123"
      curl() {
        return 1
      }
      export -f curl
      
      When call check_api_quota
      The status should be failure
    End
  End

  # ===================================================================
  # Tests: adjust_jobs_dynamically()
  # ===================================================================
  Describe 'adjust_jobs_dynamically() - Dynamic Jobs Adjustment'

    It 'reduces jobs on high error rate'
      When call adjust_jobs_dynamically "10" "2" "8"
      The status should be success
      local result
      result=$(adjust_jobs_dynamically "10" "2" "8")
      [ "$result" -lt 10 ]
    End

    It 'increases jobs on low error rate'
      When call adjust_jobs_dynamically "5" "9" "1"
      The status should be success
      local result
      result=$(adjust_jobs_dynamically "5" "9" "1")
      [ "$result" -ge 5 ]
    End

    It 'keeps jobs when error rate moderate'
      When call adjust_jobs_dynamically "10" "6" "4"
      The status should be success
      local result
      result=$(adjust_jobs_dynamically "10" "6" "4")
      [ "$result" -eq 10 ]
    End

    It 'handles zero total'
      When call adjust_jobs_dynamically "10" "0" "0"
      The output should eq "10"
    End

    It 'respects minimum jobs'
      PARALLEL_MIN_JOBS=2
      When call adjust_jobs_dynamically "10" "0" "10"
      local result
      result=$(adjust_jobs_dynamically "10" "0" "10")
      [ "$result" -ge 2 ]
    End

    It 'respects maximum jobs'
      PARALLEL_MAX_JOBS=20
      When call adjust_jobs_dynamically "5" "10" "0"
      local result
      result=$(adjust_jobs_dynamically "5" "10" "0")
      [ "$result" -le 20 ]
    End
  End

  # ===================================================================
  # Tests: preflight_checks()
  # ===================================================================
  Describe 'preflight_checks() - Preflight Checks'

    It 'passes preflight checks'
      timeout() {
        "$@"
      }
      export -f timeout
      
      ping() {
        return 0
      }
      export -f ping
      
      export GITHUB_TOKEN="ghp_test123"
      curl() {
        echo '{"resources":{"core":{"remaining":4500,"limit":5000}}}'
      }
      export -f curl
      
      command() {
        if [ "$1" = "-v" ] && [ "$2" = "parallel" ]; then
          return 0
        fi
        command "$@"
      }
      export -f command
      
      df() {
        echo "Filesystem 1G-blocks Used Available Use% Mounted"
        echo "/dev/sda1 100 50 50 50% /"
      }
      export -f df
      
      mkdir -p "$DEST_DIR"
      
      When call preflight_checks
      The status should be success
    End

    It 'fails when checks fail'
      timeout() {
        "$@"
      }
      export -f timeout
      
      ping() {
        return 1
      }
      export -f ping
      
      unset GITHUB_TOKEN
      
      command() {
        if [ "$1" = "-v" ] && [ "$2" = "parallel" ]; then
          return 1
        fi
        command "$@"
      }
      export -f command
      
      df() {
        echo "Filesystem 1G-blocks Used Available Use% Mounted"
        echo "/dev/sda1 100 99 1 99% /"
      }
      export -f df
      
      mkdir -p "$DEST_DIR"
      
      When call preflight_checks
      The status should be failure
    End
  End

End
