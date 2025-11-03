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
  # Tests: init_validation()
  # ===================================================================
  Describe 'init_validation() - Module Initialization'

    It 'initializes successfully'
      When call init_validation
      The status should be success
    End
  End

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
  # Tests: validate_filter()
  # ===================================================================
  Describe 'validate_filter() - Git Filter Validation'

    It 'accepts empty filter'
      When call validate_filter ""
      The status should be success
    End

    It 'accepts blob:none filter'
      When call validate_filter "blob:none"
      The status should be success
    End

    It 'accepts tree:0 filter'
      When call validate_filter "tree:0"
      The status should be success
    End

    It 'accepts sparse:oid filter'
      When call validate_filter "sparse:oid=abc123"
      The status should be success
    End

    It 'warns but accepts unknown filter'
      When call validate_filter "unknown:filter"
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
  # Tests: _validate_numeric_range()
  # ===================================================================
  Describe '_validate_numeric_range() - Numeric Range Validation'

    It 'validates number within range'
      When call _validate_numeric_range "5" "1" "10" "test"
      The status should be success
    End

    It 'rejects number below minimum'
      When call _validate_numeric_range "0" "1" "10" "test"
      The status should be failure
    End

    It 'rejects number above maximum'
      When call _validate_numeric_range "11" "1" "10" "test"
      The status should be failure
    End

    It 'accepts number at minimum'
      When call _validate_numeric_range "1" "1" "10" "test"
      The status should be success
    End

    It 'accepts number at maximum'
      When call _validate_numeric_range "10" "1" "10" "test"
      The status should be success
    End

    It 'rejects non-numeric value'
      When call _validate_numeric_range "abc" "1" "10" "test"
      The status should be failure
    End
  End

  # ===================================================================
  # Tests: _validate_permissions()
  # ===================================================================
  Describe '_validate_permissions() - Permission Validation'

    It 'validates readable file'
      local test_file="/tmp/test-permissions-$$.txt"
      echo "test" > "$test_file"
      chmod 644 "$test_file"
      When call _validate_permissions "$test_file" "r" "f"
      The status should be success
      rm -f "$test_file"
    End

    It 'validates writable file'
      local test_file="/tmp/test-permissions-$$.txt"
      touch "$test_file"
      chmod 644 "$test_file"
      When call _validate_permissions "$test_file" "w" "f"
      The status should be success
      rm -f "$test_file"
    End

    It 'validates executable file'
      local test_file="/tmp/test-permissions-$$.sh"
      echo "#!/bin/bash" > "$test_file"
      chmod 755 "$test_file"
      When call _validate_permissions "$test_file" "x" "f"
      The status should be success
      rm -f "$test_file"
    End

    It 'validates readable directory'
      local test_dir="/tmp/test-permissions-dir-$$"
      mkdir -p "$test_dir"
      chmod 755 "$test_dir"
      When call _validate_permissions "$test_dir" "r" "d"
      The status should be success
      rm -rf "$test_dir"
    End

    It 'validates writable directory'
      local test_dir="/tmp/test-permissions-dir-$$"
      mkdir -p "$test_dir"
      chmod 755 "$test_dir"
      When call _validate_permissions "$test_dir" "w" "d"
      The status should be success
      rm -rf "$test_dir"
    End

    It 'rejects non-existent file'
      When call _validate_permissions "/tmp/nonexistent-$$" "r" "f"
      The status should be failure
    End
  End

  # ===================================================================
  # Tests: validate_file_permissions()
  # ===================================================================
  Describe 'validate_file_permissions() - File Permission Validation'

    It 'validates readable file'
      local test_file="/tmp/test-file-perms-$$.txt"
      echo "test" > "$test_file"
      chmod 644 "$test_file"
      When call validate_file_permissions "$test_file" "r"
      The status should be success
      rm -f "$test_file"
    End

    It 'validates writable file'
      local test_file="/tmp/test-file-perms-$$.txt"
      touch "$test_file"
      chmod 644 "$test_file"
      When call validate_file_permissions "$test_file" "w"
      The status should be success
      rm -f "$test_file"
    End

    It 'rejects non-existent file'
      When call validate_file_permissions "/tmp/nonexistent-$$" "r"
      The status should be failure
    End
  End

  # ===================================================================
  # Tests: validate_dir_permissions()
  # ===================================================================
  Describe 'validate_dir_permissions() - Directory Permission Validation'

    It 'validates readable directory'
      local test_dir="/tmp/test-dir-perms-$$"
      mkdir -p "$test_dir"
      chmod 755 "$test_dir"
      When call validate_dir_permissions "$test_dir" "r"
      The status should be success
      rm -rf "$test_dir"
    End

    It 'validates writable directory'
      local test_dir="/tmp/test-dir-perms-$$"
      mkdir -p "$test_dir"
      chmod 755 "$test_dir"
      When call validate_dir_permissions "$test_dir" "w"
      The status should be success
      rm -rf "$test_dir"
    End

    It 'rejects non-existent directory'
      When call validate_dir_permissions "/tmp/nonexistent-dir-$$" "r"
      The status should be failure
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

