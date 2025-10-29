#!/usr/bin/env bash
# Mock for curl command
# Override curl for testing

mock_curl() {
  # Check for specific URLs and return appropriate responses
  if [[ "$*" =~ "api.github.com/users/validuser" ]]; then
    echo '{"login":"validuser","type":"User"}'
    return 0
  elif [[ "$*" =~ "api.github.com/orgs/validorg" ]]; then
    echo '{"login":"validorg","type":"Organization"}'
    return 0
  elif [[ "$*" =~ "api.github.com/users/invalid" ]]; then
    echo '{"message":"Not Found"}'
    return 0
  elif [[ "$*" =~ "api.github.com/user/repos" ]]; then
    echo '[{"name":"repo1","full_name":"user/repo1","clone_url":"https://github.com/user/repo1.git","ssh_url":"git@github.com:user/repo1.git"},{"name":"repo2","full_name":"user/repo2","clone_url":"https://github.com/user/repo2.git","ssh_url":"git@github.com:user/repo2.git"}]'
    return 0
  elif [[ "$*" =~ "api.github.com/users/validuser/repos" ]]; then
    echo '[{"name":"test-repo","full_name":"validuser/test-repo","clone_url":"https://github.com/validuser/test-repo.git"}]'
    return 0
  else
    # Default mock response
    echo '{"test": "mock_response"}'
    return 0
  fi
}

# Alias curl to mock_curl if in test mode
if [[ "${GIT_MIRROR_TEST_MODE:-}" == "true" ]]; then
  alias curl=mock_curl
  export -f mock_curl
fi

