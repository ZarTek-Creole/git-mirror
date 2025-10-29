#!/usr/bin/env bash
# Mock for git command
# Override git for testing

mock_git() {
  # Mock git clone
  if [[ "$1" == "clone" ]]; then
    local repo_url="$2"
    local dest_dir="${3:-}"
    
    # Simulate successful clone
    if [[ -n "$dest_dir" ]]; then
      mkdir -p "$dest_dir"
      echo "Cloning into '$dest_dir'..."
    else
      echo "Cloning..."
    fi
    return 0
  fi
  
  # Mock git pull
  if [[ "$1" == "pull" ]]; then
    echo "Already up to date."
    return 0
  fi
  
  # Mock git config
  if [[ "$1" == "config" ]]; then
    return 0
  fi
  
  # Mock git rev-parse
  if [[ "$1" == "rev-parse" ]]; then
    if [[ "$2" == "HEAD" ]]; then
      echo "abc123def456"
    fi
    return 0
  fi
  
  # Mock git ls-remote
  if [[ "$1" == "ls-remote" ]]; then
    echo "abc123	refs/heads/main"
    return 0
  fi
  
  # Default mock
  return 0
}

# Alias git to mock_git if in test mode
if [[ "${GIT_MIRROR_TEST_MODE:-}" == "true" ]]; then
  alias git=mock_git
  export -f mock_git
fi

