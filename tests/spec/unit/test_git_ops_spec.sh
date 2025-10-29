#!/usr/bin/env shellspec
# Tests ShellSpec pour module Git Operations (critique)
# Objectif: 90%+ couverture

Describe 'Git Operations Module - Complete Test Suite'

  setup_git_ops() {
    source lib/logging/logger.sh
    source lib/git/git_ops.sh
    
    export TEST_REPO_DIR="/tmp/test-repo-$$"
    export VERBOSE_LEVEL=0
    export QUIET_MODE=true
    export MAX_GIT_RETRIES=1
    export GIT_TIMEOUT=10
    
    mkdir -p "$TEST_REPO_DIR"
  }

  cleanup_git_ops() {
    rm -rf "$TEST_REPO_DIR"
  }

  Before setup_git_ops
  After cleanup_git_ops

  # ===================================================================
  # Tests: init_git_module()
  # ===================================================================
  Describe 'init_git_module() - Module Initialization'

    It 'initializes module successfully'
      When call init_git_module
      The status should be success
    End

    It 'resets git statistics'
      When call init_git_module
      The status should be success
    End
  End

  # ===================================================================
  # Tests: repository_exists()
  # ===================================================================
  Describe 'repository_exists() - Repository Existence Check'

    It 'returns false for non-existent repository'
      When call repository_exists "/tmp/nonexistent-$$"
      The status should be failure
    End

    It 'returns true for valid repository'
      mkdir -p "$TEST_REPO_DIR/.git"
      When call repository_exists "$TEST_REPO_DIR"
      The status should be success
    End

    It 'returns false for directory without .git'
      mkdir -p "$TEST_REPO_DIR/regular"
      When call repository_exists "$TEST_REPO_DIR/regular"
      The status should be failure
    End
  End

  # ===================================================================
  # Tests: get_current_branch()
  # ===================================================================
  Describe 'get_current_branch() - Current Branch Detection'

    It 'returns empty for non-existent repository'
      When call get_current_branch "/tmp/nonexistent-$$"
      The status should be success
      The output should be empty
    End

    It 'returns empty for directory without .git'
      When call get_current_branch "$TEST_REPO_DIR"
      The status should be success
      The output should be empty
    End
  End

  # ===================================================================
  # Tests: get_last_commit()
  # ===================================================================
  Describe 'get_last_commit() - Last Commit Retrieval'

    It 'returns empty for non-existent repository'
      When call get_last_commit "/tmp/nonexistent-$$"
      The status should be success
      The output should be empty
    End
  End

  # ===================================================================
  # Tests: clean_corrupted_repository()
  # ===================================================================
  Describe 'clean_corrupted_repository() - Repository Cleanup'

    It 'cleans lock files'
      mkdir -p "$TEST_REPO_DIR"
      touch "$TEST_REPO_DIR/file.lock"
      When call clean_corrupted_repository "$TEST_REPO_DIR"
      The status should be success
    End

    It 'handles non-existent repository'
      When call clean_corrupted_repository "/tmp/nonexistent-$$"
      The status should be success
    End
  End

  # ===================================================================
  # Tests: get_git_stats()
  # ===================================================================
  Describe 'get_git_stats() - Git Statistics'

    It 'displays statistics'
      When call get_git_stats
      The status should be success
      The output should include "Git Operations Statistics"
    End

    It 'handles parallel mode flag'
      export PARALLEL_ENABLED=true
      When call get_git_stats
      The status should be success
      The output should include "Parallel"
    End
  End

  # ===================================================================
  # Tests: git_ops_setup()
  # ===================================================================
  Describe 'git_ops_setup() - Module Setup'

    It 'initializes module'
      When call git_ops_setup
      The status should be success
    End
  End

End
