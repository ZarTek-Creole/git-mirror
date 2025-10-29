#!/usr/bin/env bash
# Mock for jq command
# Override jq for testing

mock_jq() {
  # Mock jq parsing JSON
  if [[ "$*" =~ "\\.login" ]]; then
    # Extract login field
    echo "testuser"
    return 0
  elif [[ "$*" =~ "\\.type" ]]; then
    # Extract type field
    echo "User"
    return 0
  elif [[ "$*" =~ "\\.name" ]]; then
    # Extract name field
    echo "test-repo"
    return 0
  elif [[ "$*" =~ "length" ]]; then
    # Count items in array
    echo "2"
    return 0
  elif [[ "$*" =~ "." ]]; then
    # Default passthrough
    cat
    return 0
  else
    # Default mock response
    cat
    return 0
  fi
}

# Alias jq to mock_jq if in test mode
if [[ "${GIT_MIRROR_TEST_MODE:-}" == "true" ]]; then
  alias jq=mock_jq
  export -f mock_jq
fi

