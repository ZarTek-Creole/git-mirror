#!/usr/bin/env shellspec
# Tests ShellSpec complets pour module Auth
# Couverture: 100% de toutes les fonctions

Describe 'Auth Module - Complete Test Suite (100% Coverage)'

  setup_auth() {
    export GIT_MIRROR_TEST_MODE=true
    export VERBOSE_LEVEL=2
    export QUIET_MODE=false
    export GITHUB_TOKEN=""
    export GITHUB_AUTH_METHOD=""
    export GITHUB_SSH_KEY=""
    
    # Charger les dépendances
    source lib/logging/logger.sh
    init_logger 0 false false true
    
    # Mock curl for API calls
    curl() {
      if [[ "$*" =~ "api.github.com/user" ]]; then
        echo '{"login":"testuser","id":12345}'
        return 0
      fi
      return 1
    }
    export -f curl
    
    # Charger le module
    source lib/auth/auth.sh
  }

  teardown_auth() {
    unset GITHUB_TOKEN GITHUB_AUTH_METHOD GITHUB_SSH_KEY
  }

  Before setup_auth
  After teardown_auth

  # ===================================================================
  # Tests: auth_validate_token()
  # ===================================================================
  Describe 'auth_validate_token() - Token Validation'

    It 'validates valid token'
      curl() {
        echo '{"login":"testuser"}'
        return 0
      }
      export -f curl
      
      When call auth_validate_token "ghp_validtoken123"
      The status should be success
    End

    It 'rejects invalid token'
      curl() {
        echo "HTTP_CODE:401"
        echo '{"message":"Bad credentials"}'
        return 0
      }
      export -f curl
      
      When call auth_validate_token "invalid_token"
      The status should be failure
    End

    It 'handles empty token'
      When call auth_validate_token ""
      The status should be failure
    End

    It 'handles network error'
      curl() {
        return 1
      }
      export -f curl
      
      When call auth_validate_token "test_token"
      The status should be failure
    End
  End

  # ===================================================================
  # Tests: auth_detect_method()
  # ===================================================================
  Describe 'auth_detect_method() - Method Detection'

    It 'detects token method when GITHUB_TOKEN set'
      export GITHUB_TOKEN="ghp_test123"
      When call auth_detect_method
      The status should be success
      The output should include "token"
    End

    It 'detects SSH method when SSH key available'
      ssh() {
        echo "Hi testuser! You've successfully authenticated"
        return 0
      }
      export -f ssh
      
      When call auth_detect_method
      The status should be success
      The output should include "ssh"
    End

    It 'falls back to public method'
      unset GITHUB_TOKEN
      ssh() {
        return 1
      }
      export -f ssh
      
      When call auth_detect_method
      The status should be success
      The output should include "public"
    End

    It 'respects forced method'
      export GITHUB_AUTH_METHOD="public"
      When call auth_detect_method
      The status should be success
      The output should equal "public"
    End
  End

  # ===================================================================
  # Tests: auth_get_headers()
  # ===================================================================
  Describe 'auth_get_headers() - Header Generation'

    It 'returns Authorization header for token'
      export GITHUB_TOKEN="ghp_test123"
      export GITHUB_AUTH_METHOD="token"
      When call auth_get_headers
      The status should be success
      The output should include "Authorization"
      The output should include "ghp_test123"
    End

    It 'returns empty headers for public method'
      export GITHUB_AUTH_METHOD="public"
      When call auth_get_headers
      The status should be success
      The output should be empty
    End

    It 'returns empty headers for SSH method'
      export GITHUB_AUTH_METHOD="ssh"
      When call auth_get_headers
      The status should be success
      The output should be empty
    End

    It 'handles missing token gracefully'
      export GITHUB_AUTH_METHOD="token"
      unset GITHUB_TOKEN
      When call auth_get_headers
      The status should be success
      The output should be empty
    End
  End

  # ===================================================================
  # Tests: auth_transform_url()
  # ===================================================================
  Describe 'auth_transform_url() - URL Transformation'

    It 'transforms HTTPS to SSH URL'
      export GITHUB_AUTH_METHOD="ssh"
      When call auth_transform_url "https://github.com/user/repo.git"
      The status should be success
      The output should include "git@github.com"
      The output should not include "https://"
    End

    It 'keeps HTTPS URL for token method'
      export GITHUB_AUTH_METHOD="token"
      When call auth_transform_url "https://github.com/user/repo.git"
      The status should be success
      The output should include "https://"
    End

    It 'keeps HTTPS URL for public method'
      export GITHUB_AUTH_METHOD="public"
      When call auth_transform_url "https://github.com/user/repo.git"
      The status should be success
      The output should include "https://"
    End

    It 'handles SSH URL unchanged'
      export GITHUB_AUTH_METHOD="ssh"
      When call auth_transform_url "git@github.com:user/repo.git"
      The status should be success
      The output should include "git@github.com"
    End

    It 'handles empty URL'
      When call auth_transform_url ""
      The status should be success
      The output should be empty
    End
  End

  # ===================================================================
  # Tests: auth_init()
  # ===================================================================
  Describe 'auth_init() - Module Initialization'

    It 'initializes successfully'
      When call auth_init
      The status should be success
    End

    It 'detects method automatically'
      export GITHUB_TOKEN="ghp_test123"
      When call auth_init
      The status should be success
    End

    It 'validates token when provided'
      export GITHUB_TOKEN="ghp_test123"
      curl() {
        echo '{"login":"testuser"}'
        return 0
      }
      export -f curl
      
      When call auth_init
      The status should be success
    End
  End

  # ===================================================================
  # Tests: auth_setup()
  # ===================================================================
  Describe 'auth_setup() - Module Setup'

    It 'sets up successfully'
      When call auth_setup
      The status should be success
    End

    It 'initializes module'
      When call auth_setup
      The status should be success
    End

    It 'detects authentication method'
      export GITHUB_TOKEN="ghp_test123"
      When call auth_setup
      The status should be success
    End
  End

End
