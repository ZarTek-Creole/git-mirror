#!/usr/bin/env shellspec
# Tests ShellSpec complets pour module State Management
# Couverture: 100% de toutes les fonctions

Describe 'State Module - Complete Test Suite (100% Coverage)'

  setup_state() {
    export GIT_MIRROR_TEST_MODE=true
    export VERBOSE_LEVEL=2
    export QUIET_MODE=false
    export STATE_FILE="/tmp/test-state-$$.json"
    export STATE_DIR="/tmp/test-state-dir-$$"
    
    # Charger les dépendances
    source lib/logging/logger.sh
    init_logger 0 false false true
    
    # Charger le module
    source lib/state/state.sh
  }

  teardown_state() {
    rm -f "$STATE_FILE" 2>/dev/null || true
    rm -rf "$STATE_DIR" 2>/dev/null || true
  }

  Before setup_state
  After teardown_state

  # ===================================================================
  # Tests: state_init()
  # ===================================================================
  Describe 'state_init() - State Initialization'

    It 'initializes successfully'
      When call state_init
      The status should be success
    End

    It 'creates state directory'
      rm -rf "$STATE_DIR"
      When call state_init
      The status should be success
      The directory "$STATE_DIR" should exist
    End

    It 'handles custom state file'
      STATE_FILE="/tmp/custom-state-$$.json"
      When call state_init
      The status should be success
      rm -f "$STATE_FILE"
    End
  End

  # ===================================================================
  # Tests: state_save()
  # ===================================================================
  Describe 'state_save() - State Saving'

    It 'saves state successfully'
      When call state_save "users" "testuser" "./repos" "100" "50" "repo1 repo2" "repo3 repo4" "false"
      The status should be success
      The file "$STATE_FILE" should exist
    End

    It 'saves interrupted state'
      When call state_save "users" "testuser" "./repos" "100" "50" "repo1" "repo2" "true"
      The status should be success
      The contents of file "$STATE_FILE" should include "true"
    End
  End

  # ===================================================================
  # Tests: state_load()
  # ===================================================================
  Describe 'state_load() - State Loading'

    It 'loads saved state'
      call state_save "users" "testuser" "./repos" "100" "50" "repo1" "repo2" "false"
      When call state_load
      The status should be success
    End

    It 'returns failure when no state file'
      rm -f "$STATE_FILE"
      When call state_load
      The status should be failure
    End

    It 'handles corrupted state file'
      echo "invalid json" > "$STATE_FILE"
      When call state_load
      The status should be failure
    End
  End

  # ===================================================================
  # Tests: state_should_resume()
  # ===================================================================
  Describe 'state_should_resume() - Resume Check'

    It 'returns false when no state file'
      rm -f "$STATE_FILE"
      When call state_should_resume
      The status should be failure
    End

    It 'returns true when interrupted'
      echo '{"interrupted": true}' > "$STATE_FILE"
      When call state_should_resume
      The status should be success
    End

    It 'returns false when not interrupted'
      echo '{"interrupted": false}' > "$STATE_FILE"
      When call state_should_resume
      The status should be failure
    End
  End

  # ===================================================================
  # Tests: state_get_info()
  # ===================================================================
  Describe 'state_get_info() - State Information'

    It 'returns info when state file exists'
      echo '{"context":"users","username":"test","destination":"./repos","total_repos":100,"processed":50,"failed":["repo1"],"success":["repo2"]}' > "$STATE_FILE"
      When call state_get_info
      The status should be success
      The output should include "users"
      The output should include "test"
    End

    It 'returns failure when no state file'
      rm -f "$STATE_FILE"
      When call state_get_info
      The status should be failure
    End
  End

  # ===================================================================
  # Tests: state_get_processed()
  # ===================================================================
  Describe 'state_get_processed() - Get Processed Repos'

    It 'returns empty array when no state file'
      rm -f "$STATE_FILE"
      When call state_get_processed
      The output should eq "[]"
    End

    It 'returns processed repos'
      echo '{"success":["repo1","repo2"]}' > "$STATE_FILE"
      When call state_get_processed
      The output should include "repo1"
      The output should include "repo2"
    End
  End

  # ===================================================================
  # Tests: state_get_failed()
  # ===================================================================
  Describe 'state_get_failed() - Get Failed Repos'

    It 'returns empty array when no state file'
      rm -f "$STATE_FILE"
      When call state_get_failed
      The output should eq "[]"
    End

    It 'returns failed repos'
      echo '{"failed":["repo1","repo2"]}' > "$STATE_FILE"
      When call state_get_failed
      The output should include "repo1"
      The output should include "repo2"
    End
  End

  # ===================================================================
  # Tests: state_add_success()
  # ===================================================================
  Describe 'state_add_success() - Add Success Repo'

    It 'adds repo to success list'
      echo '{"success":[]}' > "$STATE_FILE"
      When call state_add_success "repo1"
      The status should be success
      The contents of file "$STATE_FILE" should include "repo1"
    End

    It 'fails when no state file'
      rm -f "$STATE_FILE"
      When call state_add_success "repo1"
      The status should be failure
    End
  End

  # ===================================================================
  # Tests: state_add_failed()
  # ===================================================================
  Describe 'state_add_failed() - Add Failed Repo'

    It 'adds repo to failed list'
      echo '{"failed":[]}' > "$STATE_FILE"
      When call state_add_failed "repo1"
      The status should be success
      The contents of file "$STATE_FILE" should include "repo1"
    End

    It 'fails when no state file'
      rm -f "$STATE_FILE"
      When call state_add_failed "repo1"
      The status should be failure
    End
  End

  # ===================================================================
  # Tests: state_update_processed()
  # ===================================================================
  Describe 'state_update_processed() - Update Processed Count'

    It 'updates processed count'
      echo '{"processed":10}' > "$STATE_FILE"
      When call state_update_processed "50"
      The status should be success
      The contents of file "$STATE_FILE" should include "50"
    End

    It 'fails when no state file'
      rm -f "$STATE_FILE"
      When call state_update_processed "50"
      The status should be failure
    End
  End

  # ===================================================================
  # Tests: state_mark_interrupted()
  # ===================================================================
  Describe 'state_mark_interrupted() - Mark Interrupted'

    It 'marks state as interrupted'
      echo '{"interrupted":false}' > "$STATE_FILE"
      When call state_mark_interrupted
      The status should be success
      The contents of file "$STATE_FILE" should include "true"
    End

    It 'fails when no state file'
      rm -f "$STATE_FILE"
      When call state_mark_interrupted
      The status should be failure
    End
  End

  # ===================================================================
  # Tests: state_mark_completed()
  # ===================================================================
  Describe 'state_mark_completed() - Mark Completed'

    It 'marks state as completed'
      echo '{"interrupted":true}' > "$STATE_FILE"
      When call state_mark_completed
      The status should be success
      The contents of file "$STATE_FILE" should include "false"
    End

    It 'fails when no state file'
      rm -f "$STATE_FILE"
      When call state_mark_completed
      The status should be failure
    End
  End

  # ===================================================================
  # Tests: state_clean()
  # ===================================================================
  Describe 'state_clean() - Clean State'

    It 'removes state file'
      echo '{"test":"data"}' > "$STATE_FILE"
      When call state_clean
      The status should be success
      The file "$STATE_FILE" should not exist
    End

    It 'handles missing state file'
      rm -f "$STATE_FILE"
      When call state_clean
      The status should be success
    End
  End

  # ===================================================================
  # Tests: state_show_summary()
  # ===================================================================
  Describe 'state_show_summary() - Show Summary'

    It 'shows summary when state exists'
      echo '{"context":"users","username":"test","destination":"./repos","total_repos":100,"processed":50,"failed":["repo1"],"success":["repo2"]}' > "$STATE_FILE"
      When call state_show_summary
      The status should be success
      The output should include "users"
      The output should include "test"
    End

    It 'shows message when no state'
      rm -f "$STATE_FILE"
      When call state_show_summary
      The status should be success
      The output should include "Aucun état"
    End
  End

  # ===================================================================
  # Tests: state_setup()
  # ===================================================================
  Describe 'state_setup() - Module Setup'

    It 'initializes successfully'
      When call state_setup
      The status should be success
    End
  End

End
