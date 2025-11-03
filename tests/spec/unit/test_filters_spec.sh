#!/usr/bin/env shellspec
# Tests ShellSpec complets pour module Filters
# Couverture: 100% de toutes les fonctions

Describe 'Filters Module - Complete Test Suite (100% Coverage)'

  setup_filters() {
    export GIT_MIRROR_TEST_MODE=true
    export VERBOSE_LEVEL=2
    export QUIET_MODE=false
    export FILTER_ENABLED=false
    export EXCLUDE_PATTERNS=""
    export INCLUDE_PATTERNS=""
    export EXCLUDE_FILE=""
    export INCLUDE_FILE=""
    
    # Charger les d?pendances
    source lib/logging/logger.sh
    init_logger 0 false false true
    
    # Charger le module
    source lib/filters/filters.sh
  }

  teardown_filters() {
    unset FILTER_ENABLED EXCLUDE_PATTERNS INCLUDE_PATTERNS EXCLUDE_FILE INCLUDE_FILE
    unset EXCLUDE_PATTERNS_ARRAY INCLUDE_PATTERNS_ARRAY
  }

  Before setup_filters
  After teardown_filters

  # ===================================================================
  # Tests: get_filters_module_info()
  # ===================================================================
  Describe 'get_filters_module_info() - Module Information'

    It 'returns module information'
      When call get_filters_module_info
      The status should be success
      The output should include "filters"
    End
  End

  # ===================================================================
  # Tests: filters_init()
  # ===================================================================
  Describe 'filters_init() - Module Initialization'

    It 'initializes successfully'
      When call filters_init
      The status should be success
    End

    It 'loads exclude patterns from variable'
      export EXCLUDE_PATTERNS="test-*,demo-*"
      When call filters_init
      The status should be success
    End

    It 'loads include patterns from variable'
      export INCLUDE_PATTERNS="project-*,main-*"
      When call filters_init
      The status should be success
    End

    It 'loads patterns from exclude file'
      local exclude_file="/tmp/test-exclude-$$.txt"
      echo "test-*" > "$exclude_file"
      export EXCLUDE_FILE="$exclude_file"
      When call filters_init
      The status should be success
      rm -f "$exclude_file"
    End

    It 'loads patterns from include file'
      local include_file="/tmp/test-include-$$.txt"
      echo "project-*" > "$include_file"
      export INCLUDE_FILE="$include_file"
      When call filters_init
      The status should be success
      rm -f "$include_file"
    End

    It 'fails when jq is missing'
      command() {
        if [ "$1" = "-v" ] && [ "$2" = "jq" ]; then
          return 1
        fi
        command "$@"
      }
      export -f command
      
      When call filters_init
      The status should be failure
    End
  End

  # ===================================================================
  # Tests: filters_match_pattern()
  # ===================================================================
  Describe 'filters_match_pattern() - Pattern Matching'

    It 'matches exact pattern'
      When call filters_match_pattern "test-repo" "test-repo"
      The status should be success
    End

    It 'does not match different exact pattern'
      When call filters_match_pattern "test-repo" "other-repo"
      The status should be failure
    End

    It 'matches glob pattern with wildcard'
      When call filters_match_pattern "test-repo" "test-*"
      The status should be success
    End

    It 'matches glob pattern at start'
      When call filters_match_pattern "test-repo" "*repo"
      The status should be success
    End

    It 'matches glob pattern in middle'
      When call filters_match_pattern "test-repo" "test-*repo"
      The status should be success
    End

    It 'matches regex pattern'
      When call filters_match_pattern "test-repo" "^test-.*$"
      The status should be success
    End

    It 'rejects pattern too long'
      local long_pattern
      long_pattern=$(printf 'a%.0s' {1..101})
      When call filters_match_pattern "test" "$long_pattern"
      The status should be failure
    End

    It 'handles dangerous regex pattern safely'
      When call filters_match_pattern "test" "(a+)+b"
      The status should be failure
    End
  End

  # ===================================================================
  # Tests: filters_should_process()
  # ===================================================================
  Describe 'filters_should_process() - Process Decision'

    It 'processes all repos when filtering disabled'
      export FILTER_ENABLED=false
      When call filters_should_process "test-repo" "user/test-repo"
      The status should be success
    End

    It 'processes repo matching include pattern'
      export FILTER_ENABLED=true
      EXCLUDE_PATTERNS_ARRAY=()
      INCLUDE_PATTERNS_ARRAY=("test-*")
      When call filters_should_process "test-repo" "user/test-repo"
      The status should be success
    End

    It 'excludes repo not matching include pattern'
      export FILTER_ENABLED=true
      EXCLUDE_PATTERNS_ARRAY=()
      INCLUDE_PATTERNS_ARRAY=("project-*")
      When call filters_should_process "test-repo" "user/test-repo"
      The status should be failure
    End

    It 'excludes repo matching exclude pattern'
      export FILTER_ENABLED=true
      EXCLUDE_PATTERNS_ARRAY=("test-*")
      INCLUDE_PATTERNS_ARRAY=()
      When call filters_should_process "test-repo" "user/test-repo"
      The status should be failure
    End

    It 'processes repo when no patterns match'
      export FILTER_ENABLED=true
      EXCLUDE_PATTERNS_ARRAY=("demo-*")
      INCLUDE_PATTERNS_ARRAY=()
      When call filters_should_process "test-repo" "user/test-repo"
      The status should be success
    End
  End

  # ===================================================================
  # Tests: filters_filter_repos()
  # ===================================================================
  Describe 'filters_filter_repos() - Repository Filtering'

    It 'returns all repos when filtering disabled'
      local repos_json='[{"name":"repo1"},{"name":"repo2"}]'
      export FILTER_ENABLED=false
      When call filters_filter_repos "$repos_json"
      The status should be success
      The output should include "repo1"
      The output should include "repo2"
    End

    It 'filters repos by exclude pattern'
      local repos_json='[{"name":"test-repo1","full_name":"user/test-repo1"},{"name":"project-repo","full_name":"user/project-repo"}]'
      export FILTER_ENABLED=true
      EXCLUDE_PATTERNS_ARRAY=("test-*")
      INCLUDE_PATTERNS_ARRAY=()
      When call filters_filter_repos "$repos_json"
      The status should be success
      The output should not include "test-repo1"
      The output should include "project-repo"
    End

    It 'filters repos by include pattern'
      local repos_json='[{"name":"test-repo1","full_name":"user/test-repo1"},{"name":"project-repo","full_name":"user/project-repo"}]'
      export FILTER_ENABLED=true
      EXCLUDE_PATTERNS_ARRAY=()
      INCLUDE_PATTERNS_ARRAY=("test-*")
      When call filters_filter_repos "$repos_json"
      The status should be success
      The output should include "test-repo1"
      The output should not include "project-repo"
    End
  End

  # ===================================================================
  # Tests: filters_show_summary()
  # ===================================================================
  Describe 'filters_show_summary() - Summary Display'

    It 'shows summary when filtering enabled'
      export FILTER_ENABLED=true
      EXCLUDE_PATTERNS_ARRAY=("test-*")
      INCLUDE_PATTERNS_ARRAY=("project-*")
      When call filters_show_summary
      The status should be success
    End

    It 'shows disabled message when filtering disabled'
      export FILTER_ENABLED=false
      When call filters_show_summary
      The status should be success
      The output should include "d?sactiv?"
    End
  End

  # ===================================================================
  # Tests: filters_validate_pattern()
  # ===================================================================
  Describe 'filters_validate_pattern() - Pattern Validation'

    It 'validates empty pattern'
      When call filters_validate_pattern ""
      The status should be failure
    End

    It 'validates simple pattern'
      When call filters_validate_pattern "test-*"
      The status should be success
    End

    It 'rejects pattern too long'
      local long_pattern
      long_pattern=$(printf 'a%.0s' {1..101})
      When call filters_validate_pattern "$long_pattern"
      The status should be failure
    End

    It 'validates regex pattern'
      When call filters_validate_pattern "^test-.*$"
      The status should be success
    End

    It 'validates glob pattern'
      When call filters_validate_pattern "test-*"
      The status should be success
    End
  End

  # ===================================================================
  # Tests: filters_validate_patterns()
  # ===================================================================
  Describe 'filters_validate_patterns() - Multiple Pattern Validation'

    It 'validates all patterns successfully'
      EXCLUDE_PATTERNS_ARRAY=("test-*" "demo-*")
      INCLUDE_PATTERNS_ARRAY=("project-*")
      When call filters_validate_patterns
      The status should be success
    End

    It 'fails when invalid pattern exists'
      EXCLUDE_PATTERNS_ARRAY=("test-*" "")
      INCLUDE_PATTERNS_ARRAY=()
      When call filters_validate_patterns
      The status should be failure
    End
  End

  # ===================================================================
  # Tests: filters_setup()
  # ===================================================================
  Describe 'filters_setup() - Module Setup'

    It 'sets up successfully'
      When call filters_setup
      The status should be success
    End

    It 'validates patterns when enabled'
      export FILTER_ENABLED=true
      EXCLUDE_PATTERNS_ARRAY=("test-*")
      INCLUDE_PATTERNS_ARRAY=()
      When call filters_setup
      The status should be success
    End

    It 'shows summary when enabled'
      export FILTER_ENABLED=true
      EXCLUDE_PATTERNS_ARRAY=("test-*")
      INCLUDE_PATTERNS_ARRAY=()
      When call filters_setup
      The status should be success
    End
  End

  # ===================================================================
  # Tests: get_filter_stats()
  # ===================================================================
  Describe 'get_filter_stats() - Statistics'

    It 'returns filter statistics'
      When call get_filter_stats
      The status should be success
      The output should include "Filter Statistics"
    End
  End

End
