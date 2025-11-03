#!/usr/bin/env shellspec
# Tests ShellSpec pour module Parallel Processing

Describe 'Parallel Module - Complete Test Suite'

  setup_parallel() {
    source lib/logging/logger.sh
    source lib/parallel/parallel.sh
    export VERBOSE_LEVEL=0
    export QUIET_MODE=false
    export PARALLEL_ENABLED=false  # Désactiver pour tests unitaires
  }

  Before setup_parallel

  # ===================================================================
  # Tests: parallel_check_available()
  # ===================================================================
  Describe 'parallel_check_available() - GNU Parallel Availability'

    It 'checks for GNU parallel availability'
      When call parallel_check_available
      The status should be determined by predicate "command -v parallel >/dev/null 2>&1"
    End
  End

  # ===================================================================
  # Tests: parallel_init()
  # ===================================================================
  Describe 'parallel_init() - Parallel Initialization'

    It 'initializes successfully when disabled'
      PARALLEL_ENABLED=false
      When call parallel_init
      The status should be success
    End

    It 'handles enabled but unavailable parallel'
      PARALLEL_ENABLED=true
      When call parallel_init
      The status should be determined by predicate "command -v parallel >/dev/null 2>&1"
    End
  End

  # ===================================================================
  # Tests: get_parallel_stats()
  # ===================================================================
  Describe 'get_parallel_stats() - Parallel Statistics'

    It 'displays statistics when disabled'
      PARALLEL_ENABLED=false
      When call get_parallel_stats
      The output should include "Enabled: false"
      The output should include "Mode: Sequential"
    End

    It 'displays statistics when enabled'
      PARALLEL_ENABLED=true
      When call get_parallel_stats
      The output should include "Enabled: true"
    End

    It 'shows configured job count'
      PARALLEL_JOBS=5
      When call get_parallel_stats
      The output should include "Jobs: 5"
    End
  End

  # ===================================================================
  # Tests: parallel_setup()
  # ===================================================================
  Describe 'parallel_setup() - Module Setup'

    It 'initializes successfully'
      When call parallel_setup
      The status should be success
    End
  End

  # ===================================================================
  # Tests: parallel_wait_jobs()
  # ===================================================================
  Describe 'parallel_wait_jobs() - Job Synchronization'

    It 'returns immediately when disabled'
      PARALLEL_ENABLED=false
      When call parallel_wait_jobs
      The status should be success
    End

    It 'handles enabled state'
      PARALLEL_ENABLED=true
      When call parallel_wait_jobs
      The status should be success
    End
  End

  # ===================================================================
  # Tests: parallel_execute()
  # ===================================================================
  Describe 'parallel_execute() - Parallel Execution'

    It 'executes sequentially when disabled'
      PARALLEL_ENABLED=false
      When call parallel_execute "echo" "test1\ntest2"
      The status should be success
      The output should include "test1"
      The output should include "test2"
    End

    It 'executes sequentially with 1 job'
      PARALLEL_ENABLED=true
      When call parallel_execute "echo" "test1\ntest2" "1"
      The status should be success
    End
  End

  # ===================================================================
  # Tests: parallel_clone_repos()
  # ===================================================================
  Describe 'parallel_clone_repos() - Parallel Clone Repositories'

    It 'clones sequentially when disabled'
      PARALLEL_ENABLED=false
      clone_or_update_repo() {
        echo "Cloned: $1"
        return 0
      }
      export -f clone_or_update_repo
      
      When call parallel_clone_repos "repo1\nrepo2" "1"
      The status should be success
    End

    It 'handles empty repos list'
      PARALLEL_ENABLED=false
      When call parallel_clone_repos "" "1"
      The status should be success
    End
  End

  # ===================================================================
  # Tests: clone_wrapper()
  # ===================================================================
  Describe 'clone_wrapper() - Clone Wrapper Function'

    It 'executes clone successfully'
      clone_or_update_repo() {
        echo "Cloned: $1"
        return 0
      }
      export -f clone_or_update_repo
      
      log_info() { echo "INFO: $*"; }
      log_success() { echo "SUCCESS: $*"; }
      log_error() { echo "ERROR: $*"; }
      export -f log_info log_success log_error
      
      When call clone_wrapper "test-repo" "1"
      The status should be success
    End

    It 'handles clone failure'
      clone_or_update_repo() {
        return 1
      }
      export -f clone_or_update_repo
      
      log_info() { echo "INFO: $*"; }
      log_success() { echo "SUCCESS: $*"; }
      log_error() { echo "ERROR: $*"; }
      export -f log_info log_success log_error
      
      When call clone_wrapper "test-repo" "1"
      The status should be failure
    End
  End

  # ===================================================================
  # Tests: parallel_get_stats()
  # ===================================================================
  Describe 'parallel_get_stats() - Parallel Statistics'

    It 'shows message when no log file'
      STATE_DIR="/tmp/test-state-$$"
      mkdir -p "$STATE_DIR"
      rm -f "$STATE_DIR/parallel.log"
      When call parallel_get_stats
      The status should be success
      The output should include "Aucun log"
      rm -rf "$STATE_DIR"
    End

    It 'displays statistics from log file'
      STATE_DIR="/tmp/test-state-$$"
      mkdir -p "$STATE_DIR"
      cat > "$STATE_DIR/parallel.log" <<EOF
Seq	Host	Job	Exitval	Signal	Command
1	localhost	1	0	0	echo test1
2	localhost	2	0	0	echo test2
3	localhost	3	1	0	echo test3
EOF
      When call parallel_get_stats
      The status should be success
      The output should include "Total jobs"
      rm -rf "$STATE_DIR"
    End
  End

  # ===================================================================
  # Tests: parallel_cleanup()
  # ===================================================================
  Describe 'parallel_cleanup() - Parallel Cleanup'

    It 'cleans up when disabled'
      PARALLEL_ENABLED=false
      When call parallel_cleanup
      The status should be success
    End

    It 'cleans up when enabled'
      PARALLEL_ENABLED=true
      When call parallel_cleanup
      The status should be success
    End
  End

End

