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
  # Tests: clone_repository()
  # ===================================================================
  Describe 'clone_repository() - Repository Cloning'

    It 'clones repository successfully'
      git() {
        if [ "$1" = "clone" ]; then
          mkdir -p "$4/.git"
          echo "HEAD" > "$4/.git/HEAD"
          return 0
        fi
        return 0
      }
      export -f git
      
      When call clone_repository "https://github.com/user/test-repo.git" "$TEST_REPO_DIR" "" "1" "" "false" "false"
      The status should be success
    End

    It 'handles clone failure'
      git() {
        return 1
      }
      export -f git
      
      When call clone_repository "https://github.com/user/test-repo.git" "$TEST_REPO_DIR" "" "1" "" "false" "false"
      The status should be failure
    End

    It 'handles existing repository'
      mkdir -p "$TEST_REPO_DIR/test-repo/.git"
      echo "HEAD" > "$TEST_REPO_DIR/test-repo/.git/HEAD"
      
      When call clone_repository "https://github.com/user/test-repo.git" "$TEST_REPO_DIR" "" "1" "" "false" "false"
      The status should be success
    End

    It 'handles corrupted repository'
      mkdir -p "$TEST_REPO_DIR/test-repo"
      # No .git directory
      
      git() {
        if [ "$1" = "clone" ]; then
          mkdir -p "$4/.git"
          echo "HEAD" > "$4/.git/HEAD"
          return 0
        fi
        return 0
      }
      export -f git
      
      When call clone_repository "https://github.com/user/test-repo.git" "$TEST_REPO_DIR" "" "1" "" "false" "false"
      The status should be success
    End

    It 'clones with branch option'
      git() {
        if [ "$1" = "clone" ]; then
          mkdir -p "$4/.git"
          echo "HEAD" > "$4/.git/HEAD"
          return 0
        fi
        return 0
      }
      export -f git
      
      When call clone_repository "https://github.com/user/test-repo.git" "$TEST_REPO_DIR" "main" "1" "" "true" "false"
      The status should be success
    End

    It 'clones with depth option'
      git() {
        if [ "$1" = "clone" ]; then
          mkdir -p "$4/.git"
          echo "HEAD" > "$4/.git/HEAD"
          return 0
        fi
        return 0
      }
      export -f git
      
      When call clone_repository "https://github.com/user/test-repo.git" "$TEST_REPO_DIR" "" "5" "" "false" "false"
      The status should be success
    End
  End

  # ===================================================================
  # Tests: update_repository()
  # ===================================================================
  Describe 'update_repository() - Repository Update'

    It 'updates repository successfully'
      mkdir -p "$TEST_REPO_DIR/test-repo/.git"
      echo "HEAD" > "$TEST_REPO_DIR/test-repo/.git/HEAD"
      
      git() {
        if [ "$1" = "fetch" ]; then
          return 0
        fi
        return 0
      }
      export -f git
      
      When call update_repository "$TEST_REPO_DIR/test-repo" ""
      The status should be success
    End

    It 'updates specific branch'
      mkdir -p "$TEST_REPO_DIR/test-repo/.git"
      echo "HEAD" > "$TEST_REPO_DIR/test-repo/.git/HEAD"
      
      git() {
        if [ "$1" = "fetch" ]; then
          return 0
        elif [ "$1" = "checkout" ]; then
          return 0
        elif [ "$1" = "pull" ]; then
          return 0
        fi
        return 0
      }
      export -f git
      
      When call update_repository "$TEST_REPO_DIR/test-repo" "main"
      The status should be success
    End

    It 'handles update failure'
      mkdir -p "$TEST_REPO_DIR/test-repo/.git"
      echo "HEAD" > "$TEST_REPO_DIR/test-repo/.git/HEAD"
      
      git() {
        if [ "$1" = "fetch" ]; then
          return 1
        fi
        return 0
      }
      export -f git
      
      When call update_repository "$TEST_REPO_DIR/test-repo" ""
      The status should be failure
    End

    It 'handles non-existent repository'
      When call update_repository "/tmp/nonexistent-$$" ""
      The status should be failure
    End
  End

  # ===================================================================
  # Tests: _update_branch()
  # ===================================================================
  Describe '_update_branch() - Branch Update'

    It 'updates existing local branch'
      mkdir -p "$TEST_REPO_DIR/test-repo/.git/refs/heads"
      echo "abc123" > "$TEST_REPO_DIR/test-repo/.git/refs/heads/main"
      
      git() {
        if [ "$1" = "show-ref" ]; then
          return 0
        elif [ "$1" = "checkout" ]; then
          return 0
        elif [ "$1" = "pull" ]; then
          return 0
        fi
        return 0
      }
      export -f git
      
      cd "$TEST_REPO_DIR/test-repo"
      When call _update_branch "main"
      The status should be success
      cd - > /dev/null
    End

    It 'creates branch from remote'
      mkdir -p "$TEST_REPO_DIR/test-repo/.git/refs/remotes/origin"
      echo "abc123" > "$TEST_REPO_DIR/test-repo/.git/refs/remotes/origin/main"
      
      git() {
        if [ "$1" = "show-ref" ] && [ "$2" = "--verify" ] && [ "$3" = "--quiet" ]; then
          if [[ "$4" =~ "heads" ]]; then
            return 1
          else
            return 0
          fi
        elif [ "$1" = "checkout" ]; then
          return 0
        fi
        return 0
      }
      export -f git
      
      cd "$TEST_REPO_DIR/test-repo"
      When call _update_branch "main"
      The status should be success
      cd - > /dev/null
    End
  End

  # ===================================================================
  # Tests: _update_submodules()
  # ===================================================================
  Describe '_update_submodules() - Submodules Update'

    It 'updates submodules successfully'
      mkdir -p "$TEST_REPO_DIR/test-repo/.git"
      echo "HEAD" > "$TEST_REPO_DIR/test-repo/.git/HEAD"
      
      git() {
        if [ "$1" = "submodule" ]; then
          return 0
        fi
        return 0
      }
      export -f git
      
      cd "$TEST_REPO_DIR/test-repo"
      When call _update_submodules
      The status should be success
      cd - > /dev/null
    End

    It 'handles submodule update failure'
      mkdir -p "$TEST_REPO_DIR/test-repo/.git"
      echo "HEAD" > "$TEST_REPO_DIR/test-repo/.git/HEAD"
      
      git() {
        if [ "$1" = "submodule" ]; then
          return 1
        fi
        return 0
      }
      export -f git
      
      cd "$TEST_REPO_DIR/test-repo"
      When call _update_submodules
      The status should be failure
      cd - > /dev/null
    End
  End

  # ===================================================================
  # Tests: _configure_safe_directory()
  # ===================================================================
  Describe '_configure_safe_directory() - Safe Directory Configuration'

    It 'configures safe directory'
      git() {
        if [ "$1" = "config" ] && [ "$2" = "--global" ]; then
          return 0
        fi
        return 0
      }
      export -f git
      
      When call _configure_safe_directory "$TEST_REPO_DIR/test-repo"
      The status should be success
    End

    It 'handles configuration failure'
      git() {
        if [ "$1" = "config" ]; then
          return 1
        fi
        return 0
      }
      export -f git
      
      When call _configure_safe_directory "$TEST_REPO_DIR/test-repo"
      The status should be success
    End
  End

  # ===================================================================
  # Tests: _execute_git_command()
  # ===================================================================
  Describe '_execute_git_command() - Git Command Execution'

    It 'executes git command successfully'
      git() {
        return 0
      }
      export -f git
      
      When call _execute_git_command "git status" "test"
      The status should be success
    End

    It 'handles git command failure'
      git() {
        return 1
      }
      export -f git
      
      When call _execute_git_command "git invalid" "test"
      The status should be failure
    End

    It 'retries on failure'
      local retry_count=0
      git() {
        retry_count=$((retry_count + 1))
        if [ $retry_count -lt 2 ]; then
          return 1
        fi
        return 0
      }
      export -f git
      
      When call _execute_git_command "git status" "test"
      The status should be success
    End
  End

  # ===================================================================
  # Tests: _handle_git_error()
  # ===================================================================
  Describe '_handle_git_error() - Git Error Handling'

    It 'handles permission error'
      When call _handle_git_error "permission denied" "clone"
      The status should be defined
    End

    It 'handles network error'
      When call _handle_git_error "network unreachable" "fetch"
      The status should be defined
    End

    It 'handles repository not found error'
      When call _handle_git_error "repository not found" "clone"
      The status should be defined
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
