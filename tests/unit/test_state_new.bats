#!/usr/bin/env bats
# test_state.bats - Tests unitaires pour le module de gestion d'état

load 'test_helper.bash'

@test "state_init creates state directory" {
    local test_state_dir="/tmp/test-state"
    export STATE_DIR="$test_state_dir"
    
    run state_init
    
    [ "$status" -eq 0 ]
    [ -d "$test_state_dir" ]
    
    # Cleanup
    rm -rf "$test_state_dir"
}

@test "state_save creates state file with correct data" {
    local test_state_file="/tmp/test-state.json"
    export STATE_FILE="$test_state_file"
    
    run state_save "users" "testuser" "/tmp/repos" 100 50 "repo1,repo2" "repo3,repo4" false
    
    [ "$status" -eq 0 ]
    [ -f "$test_state_file" ]
    
    # Verify JSON content
    run jq -r '.context' "$test_state_file"
    [ "$output" = "users" ]
    
    run jq -r '.username' "$test_state_file"
    [ "$output" = "testuser" ]
    
    run jq -r '.total_repos' "$test_state_file"
    [ "$output" = "100" ]
    
    run jq -r '.processed' "$test_state_file"
    [ "$output" = "50" ]
    
    # Cleanup
    rm -f "$test_state_file"
}

@test "state_load loads existing state file" {
    local test_state_file="/tmp/test-state.json"
    export STATE_FILE="$test_state_file"
    
    # Create test state file
    cat > "$test_state_file" << 'EOF'
{
  "last_run": "2025-10-25T16:00:00Z",
  "total_repos": 100,
  "processed": 50,
  "failed": ["repo1"],
  "success": ["repo2"],
  "interrupted": false,
  "context": "users",
  "username": "testuser",
  "destination": "/tmp/repos"
}
EOF
    
    run state_load
    
    [ "$status" -eq 0 ]
    
    # Cleanup
    rm -f "$test_state_file"
}

@test "state_load fails for non-existent file" {
    local test_state_file="/tmp/non-existent.json"
    export STATE_FILE="$test_state_file"
    
    run state_load
    
    [ "$status" -eq 1 ]
}

@test "state_load fails for corrupted JSON" {
    local test_state_file="/tmp/corrupted-state.json"
    export STATE_FILE="$test_state_file"
    
    echo "invalid json" > "$test_state_file"
    
    run state_load
    
    [ "$status" -eq 1 ]
    [ ! -f "$test_state_file" ]  # Should be removed
    
    # Cleanup
    rm -f "$test_state_file"
}

@test "state_should_resume returns true for interrupted state" {
    local test_state_file="/tmp/test-state.json"
    export STATE_FILE="$test_state_file"
    
    # Create interrupted state
    cat > "$test_state_file" << 'EOF'
{
  "interrupted": true
}
EOF
    
    run state_should_resume
    
    [ "$status" -eq 0 ]
    
    # Cleanup
    rm -f "$test_state_file"
}

@test "state_should_resume returns false for completed state" {
    local test_state_file="/tmp/test-state.json"
    export STATE_FILE="$test_state_file"
    
    # Create completed state
    cat > "$test_state_file" << 'EOF'
{
  "interrupted": false
}
EOF
    
    run state_should_resume
    
    [ "$status" -eq 1 ]
    
    # Cleanup
    rm -f "$test_state_file"
}

@test "state_get_info returns correct information" {
    local test_state_file="/tmp/test-state.json"
    export STATE_FILE="$test_state_file"
    
    # Create test state file
    cat > "$test_state_file" << 'EOF'
{
  "context": "users",
  "username": "testuser",
  "destination": "/tmp/repos",
  "total_repos": 100,
  "processed": 50,
  "failed": ["repo1"],
  "success": ["repo2", "repo3"]
}
EOF
    
    run state_get_info
    
    [ "$status" -eq 0 ]
    
    IFS='|' read -r context username destination total_repos processed failed_count success_count <<< "$output"
    
    [ "$context" = "users" ]
    [ "$username" = "testuser" ]
    [ "$destination" = "/tmp/repos" ]
    [ "$total_repos" = "100" ]
    [ "$processed" = "50" ]
    [ "$failed_count" = "1" ]
    [ "$success_count" = "2" ]
    
    # Cleanup
    rm -f "$test_state_file"
}

@test "state_get_processed returns success list" {
    local test_state_file="/tmp/test-state.json"
    export STATE_FILE="$test_state_file"
    
    # Create test state file
    cat > "$test_state_file" << 'EOF'
{
  "success": ["repo1", "repo2"]
}
EOF
    
    run state_get_processed
    
    [ "$status" -eq 0 ]
    [ "$output" = '["repo1", "repo2"]' ]
    
    # Cleanup
    rm -f "$test_state_file"
}

@test "state_get_failed returns failed list" {
    local test_state_file="/tmp/test-state.json"
    export STATE_FILE="$test_state_file"
    
    # Create test state file
    cat > "$test_state_file" << 'EOF'
{
  "failed": ["repo1", "repo2"]
}
EOF
    
    run state_get_failed
    
    [ "$status" -eq 0 ]
    [ "$output" = '["repo1", "repo2"]' ]
    
    # Cleanup
    rm -f "$test_state_file"
}

@test "state_add_success adds repo to success list" {
    local test_state_file="/tmp/test-state.json"
    export STATE_FILE="$test_state_file"
    
    # Create initial state
    cat > "$test_state_file" << 'EOF'
{
  "success": ["repo1"]
}
EOF
    
    run state_add_success "repo2"
    
    [ "$status" -eq 0 ]
    
    # Verify repo was added
    run jq -r '.success | length' "$test_state_file"
    [ "$output" = "2" ]
    
    run jq -r '.success[1]' "$test_state_file"
    [ "$output" = "repo2" ]
    
    # Cleanup
    rm -f "$test_state_file"
}

@test "state_add_failed adds repo to failed list" {
    local test_state_file="/tmp/test-state.json"
    export STATE_FILE="$test_state_file"
    
    # Create initial state
    cat > "$test_state_file" << 'EOF'
{
  "failed": ["repo1"]
}
EOF
    
    run state_add_failed "repo2"
    
    [ "$status" -eq 0 ]
    
    # Verify repo was added
    run jq -r '.failed | length' "$test_state_file"
    [ "$output" = "2" ]
    
    run jq -r '.failed[1]' "$test_state_file"
    [ "$output" = "repo2" ]
    
    # Cleanup
    rm -f "$test_state_file"
}

@test "state_update_processed updates processed count" {
    local test_state_file="/tmp/test-state.json"
    export STATE_FILE="$test_state_file"
    
    # Create initial state
    cat > "$test_state_file" << 'EOF'
{
  "processed": 10
}
EOF
    
    run state_update_processed 25
    
    [ "$status" -eq 0 ]
    
    # Verify count was updated
    run jq -r '.processed' "$test_state_file"
    [ "$output" = "25" ]
    
    # Cleanup
    rm -f "$test_state_file"
}

@test "state_mark_interrupted marks state as interrupted" {
    local test_state_file="/tmp/test-state.json"
    export STATE_FILE="$test_state_file"
    
    # Create initial state
    cat > "$test_state_file" << 'EOF'
{
  "interrupted": false
}
EOF
    
    run state_mark_interrupted
    
    [ "$status" -eq 0 ]
    
    # Verify state was marked as interrupted
    run jq -r '.interrupted' "$test_state_file"
    [ "$output" = "true" ]
    
    # Cleanup
    rm -f "$test_state_file"
}

@test "state_mark_completed marks state as completed" {
    local test_state_file="/tmp/test-state.json"
    export STATE_FILE="$test_state_file"
    
    # Create initial state
    cat > "$test_state_file" << 'EOF'
{
  "interrupted": true
}
EOF
    
    run state_mark_completed
    
    [ "$status" -eq 0 ]
    
    # Verify state was marked as completed
    run jq -r '.interrupted' "$test_state_file"
    [ "$output" = "false" ]
    
    # Cleanup
    rm -f "$test_state_file"
}

@test "state_clean removes state file" {
    local test_state_file="/tmp/test-state.json"
    export STATE_FILE="$test_state_file"
    
    # Create test state file
    echo '{"test": "data"}' > "$test_state_file"
    
    run state_clean
    
    [ "$status" -eq 0 ]
    [ ! -f "$test_state_file" ]
}

@test "state_show_summary displays state information" {
    local test_state_file="/tmp/test-state.json"
    export STATE_FILE="$test_state_file"
    
    # Create test state file
    cat > "$test_state_file" << 'EOF'
{
  "context": "users",
  "username": "testuser",
  "destination": "/tmp/repos",
  "total_repos": 100,
  "processed": 50,
  "failed": ["repo1"],
  "success": ["repo2", "repo3"]
}
EOF
    
    run state_show_summary
    
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Contexte: users" ]]
    [[ "$output" =~ "Utilisateur: testuser" ]]
    [[ "$output" =~ "Total dépôts: 100" ]]
    
    # Cleanup
    rm -f "$test_state_file"
}

@test "state_setup initializes state module" {
    local test_state_dir="/tmp/test-state"
    export STATE_DIR="$test_state_dir"
    
    run state_setup
    
    [ "$status" -eq 0 ]
    [ -d "$test_state_dir" ]
    
    # Cleanup
    rm -rf "$test_state_dir"
}
