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

End

