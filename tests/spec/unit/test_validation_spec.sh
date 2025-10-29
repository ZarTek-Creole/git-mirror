#!/usr/bin/env shellspec
# Tests ShellSpec pour module Validation (critique - sécurité)

Describe 'Validation Module - Complete Test Suite'

  setup_validation() {
    source lib/logging/logger.sh
    source lib/validation/validation.sh
    export VERBOSE_LEVEL=0
    export QUIET_MODE=false
  }

  Before setup_validation

  # ===================================================================
  # Tests: validate_context()
  # ===================================================================
  Describe 'validate_context() - Context Validation'

    It 'accepts "users" context'
      When call validate_context "users"
      The status should be success
    End

    It 'accepts "orgs" context'
      When call validate_context "orgs"
      The status should be success
    End

    It 'rejects invalid context'
      When call validate_context "invalid"
      The status should be failure
    End

    It 'rejects empty context'
      When call validate_context ""
      The status should be failure
    End
  End

  # ===================================================================
  # Tests: validate_username()
  # ===================================================================
  Describe 'validate_username() - GitHub Username Validation'

    It 'accepts valid username'
      When call validate_username "myuser"
      The status should be success
    End

    It 'accepts username with hyphens'
      When call validate_username "my-username"
      The status should be success
    End

    It 'accepts single character username'
      When call validate_username "a"
      The status should be success
    End

    It 'rejects username with underscores'
      When call validate_username "my_username"
      The status should be failure
    End

    It 'rejects username starting with hyphen'
      When call validate_username "-myuser"
      The status should be failure
    End

    It 'rejects username ending with hyphen'
      When call validate_username "myuser-"
      The status should be failure
    End

    It 'rejects username too long (>39 characters)'
      When call validate_username "aaaaaaaaaabbbbbbbbbbccccccccccddddddddddeeeeeeeeee"
      The status should be failure
    End

    It 'rejects empty username'
      When call validate_username ""
      The status should be failure
    End

    It 'accepts numeric username'
      When call validate_username "12345"
      The status should be success
    End
  End

  # ===================================================================
  # Tests: validate_branch()
  # ===================================================================
  Describe 'validate_branch() - Git Branch Name Validation'

    It 'accepts valid branch name'
      When call validate_branch "feature/test"
      The status should be success
    End

    It 'accepts empty branch name (default branch)'
      When call validate_branch ""
      The status should be success
    End

    It 'rejects branch name with double dots (path traversal)'
      When call validate_branch "branch../name"
      The status should be failure
    End

    It 'rejects branch name with special Git characters'
      When call validate_branch "branch:name"
      The status should be failure
    End

    It 'rejects branch name with ref ambiguity'
      When call validate_branch "branch@{name}"
      The status should be failure
    End

    It 'rejects branch name ending with dot'
      When call validate_branch "branchname."
      The status should be failure
    End

    It 'rejects branch name with ref ambiguity'
      When call validate_branch "branch@{name}"
      The status should be failure
    End

    It 'rejects branch name too long (>255 characters)'
      local long_branch="branch-$(printf 'a%.0s' {1..260})"
      When call validate_branch "$long_branch"
      The status should be failure
    End
  End

  # ===================================================================
  # Tests: validate_destination()
  # ===================================================================
  Describe 'validate_destination() - Destination Directory Validation'

    It 'validates existing writable directory'
      local test_dir=$(mktemp -d)
      When call validate_destination "$test_dir"
      The status should be success
      rm -rf "$test_dir"
    End

    It 'validates existing parent directory (absolute path)'
      local test_dir="/tmp/test-$$"
      mkdir -p "$test_dir"
      When call validate_destination "$test_dir/child"
      The status should be success
      rm -rf "$test_dir"
    End

    It 'validates relative path'
      When call validate_destination "./test-dir"
      The status should be success
    End

    It 'rejects empty path'
      When call validate_destination ""
      The status should be failure
    End
  End

  # ===================================================================
  # Tests: _validate_numeric_range() - Tested via public functions
  # Removed: Internal function testing moved to integration tests
  # The _validate_numeric_range is tested indirectly via validate_depth,
  # validate_parallel_jobs, and validate_timeout
  # ===================================================================

  # ===================================================================
  # Tests: validate_depth()
  # ===================================================================
  Describe 'validate_depth() - Git Clone Depth Validation'

    It 'accepts valid depth'
      When call validate_depth "10"
      The status should be success
    End

    It 'rejects depth too small (<1)'
      When call validate_depth "0"
      The status should be failure
    End

    It 'rejects depth too large (>1000)'
      When call validate_depth "1001"
      The status should be failure
    End

    It 'accepts maximum allowed depth'
      When call validate_depth "1000"
      The status should be success
    End
  End

  # ===================================================================
  # Tests: validate_parallel_jobs()
  # ===================================================================
  Describe 'validate_parallel_jobs() - Parallel Jobs Validation'

    It 'accepts valid number of jobs'
      When call validate_parallel_jobs "5"
      The status should be success
    End

    It 'rejects zero jobs'
      When call validate_parallel_jobs "0"
      The status should be failure
    End

    It 'rejects too many jobs (>50)'
      When call validate_parallel_jobs "51"
      The status should be failure
    End

    It 'accepts maximum allowed jobs'
      When call validate_parallel_jobs "50"
      The status should be success
    End
  End

  # ===================================================================
  # Tests: validate_timeout()
  # ===================================================================
  Describe 'validate_timeout() - Timeout Validation'

    It 'accepts valid timeout'
      When call validate_timeout "30"
      The status should be success
    End

    It 'accepts empty timeout (default)'
      When call validate_timeout ""
      The status should be success
    End

    It 'rejects timeout too small (<1)'
      When call validate_timeout "0"
      The status should be failure
    End

    It 'rejects timeout too large (>3600)'
      When call validate_timeout "3601"
      The status should be failure
    End

    It 'accepts maximum allowed timeout'
      When call validate_timeout "3600"
      The status should be success
    End
  End

  # ===================================================================
  # Tests: validate_github_url()
  # ===================================================================
  Describe 'validate_github_url() - GitHub URL Validation'

    It 'accepts valid HTTPS URL'
      When call validate_github_url "https://github.com/user/repo.git"
      The status should be success
    End

    It 'accepts valid SSH URL'
      When call validate_github_url "git@github.com:user/repo.git"
      The status should be success
    End

    It 'rejects invalid URL'
      When call validate_github_url "http://example.com/repo.git"
      The status should be failure
    End

    It 'rejects malformed URL'
      When call validate_github_url "github.com/repo"
      The status should be failure
    End
  End

  # ===================================================================
  # Tests: validate_all_params()
  # ===================================================================
  Describe 'validate_all_params() - Complete Parameter Validation'

    It 'validates all correct parameters'
      When call validate_all_params "users" "testuser" "./repos" "main" "" "1" "1" "30"
      The status should be success
    End

    It 'rejects invalid context'
      When call validate_all_params "invalid" "testuser" "./repos" "main" "" "1" "1" "30"
      The status should be failure
    End

    It 'rejects invalid username'
      When call validate_all_params "users" "" "./repos" "main" "" "1" "1" "30"
      The status should be failure
    End
  End

  # ===================================================================
  # Tests: validate_setup()
  # ===================================================================
  Describe 'validate_setup() - Module Initialization'

    It 'initializes successfully'
      When call validate_setup
      The status should be success
    End
  End

  # ===================================================================
  # Tests: get_validation_module_info()
  # ===================================================================
  Describe 'get_validation_module_info() - Module Information'

    It 'displays module information'
      When call get_validation_module_info
      The status should be success
      The output should include "Module: validation"
      The output should include "context"
    End
  End

End

