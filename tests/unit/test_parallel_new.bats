#!/usr/bin/env bats
# test_parallel.bats - Tests unitaires pour le module de parallélisation

load 'test_helper.bash'

@test "parallel_check_available detects GNU parallel" {
    # Mock parallel command
    parallel() {
        echo "GNU parallel 20220422"
        return 0
    }
    
    run parallel_check_available
    
    [ "$status" -eq 0 ]
}

@test "parallel_check_available fails when parallel not available" {
    # Mock parallel command failure
    parallel() {
        return 1
    }
    
    run parallel_check_available
    
    [ "$status" -eq 1 ]
}

@test "parallel_init initializes parallel module" {
    export PARALLEL_ENABLED=true
    export PARALLEL_JOBS=4
    
    # Mock parallel command
    parallel() {
        echo "GNU parallel 20220422"
        return 0
    }
    
    run parallel_init
    
    [ "$status" -eq 0 ]
}

@test "parallel_init falls back to sequential when parallel disabled" {
    export PARALLEL_ENABLED=false
    
    run parallel_init
    
    [ "$status" -eq 0 ]
}

@test "parallel_execute runs commands sequentially when disabled" {
    export PARALLEL_ENABLED=false
    
    # Mock command
    test_command() {
        echo "processed: $1"
    }
    
    run parallel_execute "test_command" "item1\nitem2\nitem3"
    
    [ "$status" -eq 0 ]
    [[ "$output" =~ "processed: item1" ]]
    [[ "$output" =~ "processed: item2" ]]
    [[ "$output" =~ "processed: item3" ]]
}

@test "parallel_execute runs commands in parallel when enabled" {
    export PARALLEL_ENABLED=true
    export PARALLEL_JOBS=2
    
    # Mock parallel command
    parallel() {
        echo "parallel executed with $@"
        return 0
    }
    
    run parallel_execute "test_command" "item1\nitem2\nitem3" 2
    
    [ "$status" -eq 0 ]
    [[ "$output" =~ "parallel executed" ]]
}

@test "parallel_wait_jobs waits for background jobs" {
    export PARALLEL_ENABLED=true
    
    # Mock jobs command
    jobs() {
        echo "job1"
        echo "job2"
    }
    
    # Mock wait command
    wait() {
        echo "wait called"
    }
    
    run parallel_wait_jobs
    
    [ "$status" -eq 0 ]
}

@test "parallel_get_stats displays parallel statistics" {
    local test_log_file="/tmp/parallel.log"
    export STATE_DIR="/tmp"
    
    # Create test log file
    cat > "$test_log_file" << 'EOF'
1	job1	Exitval:0
2	job2	Exitval:1
3	job3	Exitval:0
EOF
    
    run parallel_get_stats
    
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Total jobs: 3" ]]
    [[ "$output" =~ "Succès: 2" ]]
    [[ "$output" =~ "Échecs: 1" ]]
    
    # Cleanup
    rm -f "$test_log_file"
}

@test "parallel_cleanup removes parallel log" {
    local test_log_file="/tmp/parallel.log"
    export STATE_DIR="/tmp"
    
    # Create test log file
    echo "test log" > "$test_log_file"
    
    run parallel_cleanup
    
    [ "$status" -eq 0 ]
    [ ! -f "$test_log_file" ]
    
    # Cleanup
    rm -f "$test_log_file"
}

@test "parallel_setup initializes parallel module" {
    export PARALLEL_ENABLED=true
    export PARALLEL_JOBS=4
    
    # Mock parallel command
    parallel() {
        echo "GNU parallel 20220422"
        return 0
    }
    
    run parallel_setup
    
    [ "$status" -eq 0 ]
}
