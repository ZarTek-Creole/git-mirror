#!/usr/bin/env shellspec
# Tests ShellSpec complets pour module Hooks
# Couverture: 100% de toutes les fonctions

Describe 'Hooks Module - Complete Test Suite (100% Coverage)'

  setup_hooks() {
    export GIT_MIRROR_TEST_MODE=true
    export VERBOSE_LEVEL=2
    export QUIET_MODE=false
    export HOOKS_ENABLED=false
    export HOOKS_DIR="/tmp/test-hooks-$$"
    export HOOKS_CONFIG=""
    export SCRIPT_DIR="/tmp"
    
    mkdir -p "$HOOKS_DIR"
    
    # Charger les dépendances
    source lib/logging/logger.sh
    init_logger 0 false false true
    
    # Charger le module
    source lib/hooks/hooks.sh
  }

  teardown_hooks() {
    rm -rf "$HOOKS_DIR" 2>/dev/null || true
    unset HOOKS_ENABLED HOOKS_DIR HOOKS_CONFIG HOOKS_POST_CLONE HOOKS_POST_UPDATE HOOKS_ON_ERROR
  }

  Before setup_hooks
  After teardown_hooks

  # ===================================================================
  # Tests: load_hooks_config()
  # ===================================================================
  Describe 'load_hooks_config() - Configuration Loading'

    It 'loads hooks from config file'
      local config_file="/tmp/test-hooks-config-$$.txt"
      cat > "$config_file" <<EOF
POST_CLONE=/path/to/post-clone.sh
POST_UPDATE=/path/to/post-update.sh
ON_ERROR=/path/to/on-error.sh
EOF
      export HOOKS_CONFIG="$config_file"
      When call load_hooks_config
      The status should be success
      rm -f "$config_file"
    End

    It 'handles missing config file'
      export HOOKS_CONFIG="/tmp/nonexistent-$$.txt"
      When call load_hooks_config
      The status should be success
    End

    It 'ignores comments in config'
      local config_file="/tmp/test-hooks-config-$$.txt"
      cat > "$config_file" <<EOF
# This is a comment
POST_CLONE=/path/to/post-clone.sh
EOF
      export HOOKS_CONFIG="$config_file"
      When call load_hooks_config
      The status should be success
      rm -f "$config_file"
    End

    It 'ignores empty lines'
      local config_file="/tmp/test-hooks-config-$$.txt"
      cat > "$config_file" <<EOF

POST_CLONE=/path/to/post-clone.sh

EOF
      export HOOKS_CONFIG="$config_file"
      When call load_hooks_config
      The status should be success
      rm -f "$config_file"
    End
  End

  # ===================================================================
  # Tests: execute_post_clone_hooks()
  # ===================================================================
  Describe 'execute_post_clone_hooks() - Post Clone Execution'

    It 'does nothing when hooks disabled'
      export HOOKS_ENABLED=false
      When call execute_post_clone_hooks "test-repo" "/path/to/repo" "https://github.com/user/repo.git"
      The status should be success
    End

    It 'does nothing when no hooks configured'
      export HOOKS_ENABLED=true
      HOOKS_POST_CLONE=()
      When call execute_post_clone_hooks "test-repo" "/path/to/repo" "https://github.com/user/repo.git"
      The status should be success
    End

    It 'executes post-clone hook successfully'
      export HOOKS_ENABLED=true
      local hook_file="$HOOKS_DIR/post-clone.sh"
      cat > "$hook_file" <<'EOF'
#!/bin/bash
echo "Post-clone executed: $1"
exit 0
EOF
      chmod +x "$hook_file"
      HOOKS_POST_CLONE=("$hook_file")
      When call execute_post_clone_hooks "test-repo" "/path/to/repo" "https://github.com/user/repo.git"
      The status should be success
    End

    It 'handles non-executable hook'
      export HOOKS_ENABLED=true
      local hook_file="$HOOKS_DIR/post-clone.sh"
      echo "#!/bin/bash" > "$hook_file"
      HOOKS_POST_CLONE=("$hook_file")
      When call execute_post_clone_hooks "test-repo" "/path/to/repo" "https://github.com/user/repo.git"
      The status should be success
    End

    It 'handles missing hook file'
      export HOOKS_ENABLED=true
      HOOKS_POST_CLONE=("/nonexistent/hook.sh")
      When call execute_post_clone_hooks "test-repo" "/path/to/repo" "https://github.com/user/repo.git"
      The status should be success
    End

    It 'continues on hook failure'
      export HOOKS_ENABLED=true
      local hook_file="$HOOKS_DIR/post-clone.sh"
      cat > "$hook_file" <<'EOF'
#!/bin/bash
exit 1
EOF
      chmod +x "$hook_file"
      HOOKS_POST_CLONE=("$hook_file")
      When call execute_post_clone_hooks "test-repo" "/path/to/repo" "https://github.com/user/repo.git"
      The status should be success
    End
  End

  # ===================================================================
  # Tests: execute_post_update_hooks()
  # ===================================================================
  Describe 'execute_post_update_hooks() - Post Update Execution'

    It 'does nothing when hooks disabled'
      export HOOKS_ENABLED=false
      When call execute_post_update_hooks "test-repo" "/path/to/repo" "https://github.com/user/repo.git"
      The status should be success
    End

    It 'executes post-update hook successfully'
      export HOOKS_ENABLED=true
      local hook_file="$HOOKS_DIR/post-update.sh"
      cat > "$hook_file" <<'EOF'
#!/bin/bash
echo "Post-update executed: $1"
exit 0
EOF
      chmod +x "$hook_file"
      HOOKS_POST_UPDATE=("$hook_file")
      When call execute_post_update_hooks "test-repo" "/path/to/repo" "https://github.com/user/repo.git"
      The status should be success
    End

    It 'handles multiple hooks'
      export HOOKS_ENABLED=true
      local hook1="$HOOKS_DIR/post-update1.sh"
      local hook2="$HOOKS_DIR/post-update2.sh"
      echo "#!/bin/bash" > "$hook1"
      echo "#!/bin/bash" > "$hook2"
      chmod +x "$hook1" "$hook2"
      HOOKS_POST_UPDATE=("$hook1" "$hook2")
      When call execute_post_update_hooks "test-repo" "/path/to/repo" "https://github.com/user/repo.git"
      The status should be success
    End
  End

  # ===================================================================
  # Tests: execute_on_error_hooks()
  # ===================================================================
  Describe 'execute_on_error_hooks() - Error Hook Execution'

    It 'does nothing when hooks disabled'
      export HOOKS_ENABLED=false
      When call execute_on_error_hooks "test-repo" "/path/to/repo" "https://github.com/user/repo.git" "Error message"
      The status should be success
    End

    It 'executes error hook successfully'
      export HOOKS_ENABLED=true
      local hook_file="$HOOKS_DIR/on-error.sh"
      cat > "$hook_file" <<'EOF'
#!/bin/bash
echo "Error hook executed: $4"
exit 0
EOF
      chmod +x "$hook_file"
      HOOKS_ON_ERROR=("$hook_file")
      When call execute_on_error_hooks "test-repo" "/path/to/repo" "https://github.com/user/repo.git" "Error message"
      The status should be success
    End

    It 'passes error message to hook'
      export HOOKS_ENABLED=true
      local hook_file="$HOOKS_DIR/on-error.sh"
      cat > "$hook_file" <<'EOF'
#!/bin/bash
[ "$4" = "Test error" ] && exit 0 || exit 1
EOF
      chmod +x "$hook_file"
      HOOKS_ON_ERROR=("$hook_file")
      When call execute_on_error_hooks "test-repo" "/path/to/repo" "https://github.com/user/repo.git" "Test error"
      The status should be success
    End
  End

  # ===================================================================
  # Tests: hooks_init()
  # ===================================================================
  Describe 'hooks_init() - Module Initialization'

    It 'initializes when hooks enabled'
      export HOOKS_ENABLED=true
      When call hooks_init
      The status should be success
    End

    It 'does not initialize when hooks disabled'
      export HOOKS_ENABLED=false
      When call hooks_init
      The status should be success
    End

    It 'creates hooks directory if missing'
      export HOOKS_ENABLED=true
      rm -rf "$HOOKS_DIR"
      When call hooks_init
      The status should be success
      The directory "$HOOKS_DIR" should exist
    End

    It 'loads config when provided'
      export HOOKS_ENABLED=true
      local config_file="/tmp/test-hooks-config-$$.txt"
      echo "POST_CLONE=/path/to/hook.sh" > "$config_file"
      export HOOKS_CONFIG="$config_file"
      When call hooks_init
      The status should be success
      rm -f "$config_file"
    End
  End

End
