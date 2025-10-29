#!/bin/bash
# Spec Helper for ShellSpec tests
# This file is automatically loaded before each test

# Get the project root directory
spec_helper__project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Set up environment for tests
spec_helper__test_dir="${spec_helper__project_root}/tests"
spec_helper__lib_dir="${spec_helper__project_root}/lib"
spec_helper__config_dir="${spec_helper__project_root}/config"

# Source necessary modules (will be done per-test as needed)
# spec_helper__load_module() {
#   local module="$1"
#   source "${spec_helper__lib_dir}/${module}"
# }

# Helper functions available to all tests
spec_helper_setup() {
  export TEST_TMP_DIR="${SHELLSPEC_TMPBASE:-/tmp}"
  export GIT_MIRROR_TEST_MODE=true
}

spec_helper_cleanup() {
  # Clean up test artifacts if needed
  true
}

# Export helper variables
export spec_helper__project_root
export spec_helper__test_dir
export spec_helper__lib_dir
export spec_helper__config_dir

