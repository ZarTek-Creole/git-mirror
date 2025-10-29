#!/usr/bin/env shellspec
# Tests ShellSpec pour module Authentication (critique - sécurité)
# Objectif: 90%+ couverture

Describe 'Auth Module - Complete Test Suite'

  setup_auth() {
    source lib/logging/logger.sh
    source lib/auth/auth.sh
    
    unset GITHUB_TOKEN
    unset GITHUB_AUTH_METHOD
    unset GITHUB_SSH_KEY
  }

  Before setup_auth

  # ===================================================================
  # Tests: auth_get_headers()
  # ===================================================================
  Describe 'auth_get_headers() - Header Generation'

    It 'returns headers for token method'
      export GITHUB_TOKEN="test_token_ghp_1234567890abcdef1234567890abcdef12"
      When call auth_get_headers "token"
      The status should be success
      The output should include "Authorization"
    End

    It 'returns empty for SSH method'
      When call auth_get_headers "ssh"
      The status should be success
      The output should be empty
    End

    It 'returns empty for public method'
      When call auth_get_headers "public"
      The status should be success
      The output should be empty
    End

    It 'returns empty when no token for token method'
      When call auth_get_headers "token"
      The status should be success
      The output should be empty
    End
  End

  # ===================================================================
  # Tests: auth_transform_url()
  # ===================================================================
  Describe 'auth_transform_url() - URL Transformation'

    It 'converts HTTPS to SSH'
      When call auth_transform_url "https://github.com/user/repo.git" "ssh"
      The status should be success
      The output should include "git@github.com"
    End

    It 'converts SSH to HTTPS for token'
      When call auth_transform_url "git@github.com:user/repo.git" "token"
      The status should be success
      The output should include "https://github.com"
    End

    It 'keeps SSH for SSH method'
      When call auth_transform_url "git@github.com:user/repo.git" "ssh"
      The status should be success
      The output should include "git@github.com"
    End

    It 'keeps HTTPS for public method'
      local result
      result=$(auth_transform_url "https://github.com/user/repo.git" "public")
      When call echo "$result"
      The output should include "https://github.com"
    End

    It 'handles invalid URL'
      When call auth_transform_url "invalid-url" "ssh"
      The status should be success
      The output should eq "invalid-url"
    End
  End

  # ===================================================================
  # Tests: auth_validate_token()
  # ===================================================================
  Describe 'auth_validate_token() - Token Validation'

    It 'rejects empty token'
      When call auth_validate_token ""
      The status should be failure
    End

    It 'validates format of modern token'
      When call auth_validate_token "ghp_1234567890abcdef1234567890abcdef12"
      The status should be failure
    End

    It 'validates format of classic token'
      When call auth_validate_token "1234567890123456789012345678901234567890"
      The status should be failure
    End

    It 'rejects invalid token format'
      When call auth_validate_token "invalid-token-format"
      The status should be failure
    End
  End

End

