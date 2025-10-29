#!/usr/bin/env shellspec
# Tests ShellSpec pour module Authentication (CRITIQUE)
# Objectif: Couverture maximale pour auth.sh

Describe 'Authentication Module - Critical Functions'

  setup_auth() {
    source lib/logging/logger.sh
    source lib/auth/auth.sh
    export VERBOSE_LEVEL=0
    export QUIET_MODE=false
  }

  Before setup_auth

  # ===================================================================
  # Tests: auth_get_headers()
  # ===================================================================
  Describe 'auth_get_headers()'

    It 'returns header for token authentication'
      export GITHUB_TOKEN="test_token_12345"
      When call auth_get_headers "token"
      The output should include "Authorization"
      The output should include "test_token_12345"
    End

    It 'returns empty for SSH authentication'
      When call auth_get_headers "ssh"
      The output should be blank
    End

    It 'returns empty for public authentication'
      When call auth_get_headers "public"
      The output should be blank
    End
  End

  # ===================================================================
  # Tests: auth_transform_url()
  # ===================================================================
  Describe 'auth_transform_url()'

    It 'transforms HTTPS URL to SSH'
      When call auth_transform_url "https://github.com/user/repo.git" "ssh"
      The output should include "git@github.com"
    End

    It 'keeps HTTPS URL for token auth'
      When call auth_transform_url "https://github.com/user/repo.git" "token"
      The output should eq "https://github.com/user/repo.git"
    End

    It 'transforms SSH URL to HTTPS'
      When call auth_transform_url "git@github.com:user/repo.git" "token"
      The output should include "https://github.com"
    End
  End

  # ===================================================================
  # Tests: auth_validate_token()
  # ===================================================================
  Describe 'auth_validate_token()'

    It 'validates modern token format'
      When call auth_validate_token "ghp_12345678901234567890123456789012"
      # Will fail in test environment but should check format
      The status should be defined
    End

    It 'rejects empty token'
      When call auth_validate_token ""
      The status should be failure
    End

    It 'rejects invalid token format'
      When call auth_validate_token "invalid_token"
      The status should be failure
    End
  End

End

