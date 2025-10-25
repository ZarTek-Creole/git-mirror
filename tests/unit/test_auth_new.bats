#!/usr/bin/env bats
# test_auth.bats - Tests unitaires pour le module d'authentification

load 'test_helper.bash'

@test "auth_detect_method detects token when GITHUB_TOKEN is set" {
    export GITHUB_TOKEN="test_token_1234567890123456789012345678901234567890"
    unset GITHUB_AUTH_METHOD
    
    # Mocker auth_validate_token pour retourner true
    auth_validate_token() {
        return 0
    }
    
    run auth_detect_method
    
    [ "$status" -eq 0 ]
    [ "$output" = "token" ]
}

@test "auth_detect_method detects ssh when SSH is configured" {
    unset GITHUB_TOKEN
    unset GITHUB_AUTH_METHOD
    
    # Mock SSH success
    ssh() {
        echo "Hi username! You've successfully authenticated, but GitHub does not provide shell access."
        return 0
    }
    
    run auth_detect_method
    
    [ "$status" -eq 0 ]
    [ "$output" = "ssh" ]
}

@test "auth_detect_method falls back to public when no auth available" {
    unset GITHUB_TOKEN
    unset GITHUB_AUTH_METHOD
    
    # Mock SSH failure
    ssh() {
        echo "Permission denied (publickey)."
        return 1
    }
    
    run auth_detect_method
    
    [ "$status" -eq 0 ]
    [ "$output" = "public" ]
}

@test "auth_validate_token validates correct token format" {
    export GITHUB_TOKEN="1234567890123456789012345678901234567890"
    
    # Mock successful API call
    curl() {
        echo '{"login": "testuser", "id": 12345}'
        return 0
    }
    
    run auth_validate_token "$GITHUB_TOKEN"
    
    [ "$status" -eq 0 ]
}

@test "auth_validate_token rejects invalid token format" {
    export GITHUB_TOKEN="invalid_token"
    
    run auth_validate_token "$GITHUB_TOKEN"
    
    [ "$status" -eq 1 ]
}

@test "auth_validate_token rejects empty token" {
    export GITHUB_TOKEN=""
    
    run auth_validate_token "$GITHUB_TOKEN"
    
    [ "$status" -eq 1 ]
}

@test "auth_get_headers returns correct headers for token method" {
    export GITHUB_TOKEN="test_token"
    
    run auth_get_headers "token"
    
    [ "$status" -eq 0 ]
    [ "$output" = '-H "Authorization: token test_token"' ]
}

@test "auth_get_headers returns empty headers for ssh method" {
    run auth_get_headers "ssh"
    
    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

@test "auth_get_headers returns empty headers for public method" {
    run auth_get_headers "public"
    
    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

@test "auth_transform_url converts HTTPS to SSH" {
    run auth_transform_url "https://github.com/user/repo" "ssh"
    
    [ "$status" -eq 0 ]
    [ "$output" = "git@github.com:user/repo" ]
}

@test "auth_transform_url converts SSH to HTTPS" {
    run auth_transform_url "git@github.com:user/repo" "token"
    
    [ "$status" -eq 0 ]
    [ "$output" = "https://github.com/user/repo" ]
}

@test "auth_transform_url keeps HTTPS for token method" {
    run auth_transform_url "https://github.com/user/repo" "token"
    
    [ "$status" -eq 0 ]
    [ "$output" = "https://github.com/user/repo" ]
}

@test "auth_init initializes authentication successfully" {
    export GITHUB_TOKEN="1234567890123456789012345678901234567890"
    unset GITHUB_AUTH_METHOD
    
    # Mock successful API call
    curl() {
        echo '{"login": "testuser", "id": 12345}'
        return 0
    }
    
    run auth_init 2>/dev/null
    
    [ "$status" -eq 0 ]
    # Extraire la dernière ligne qui contient "token"
    local last_line=$(echo "$output" | tail -n1)
    [ "$last_line" = "token" ]
}

@test "auth_setup configures authentication" {
    export GITHUB_TOKEN="1234567890123456789012345678901234567890"
    unset GITHUB_AUTH_METHOD
    
    # Mock successful API call
    curl() {
        echo '{"login": "testuser", "id": 12345}'
        return 0
    }
    
    run auth_setup 2>/dev/null
    
    [ "$status" -eq 0 ]
    # Extraire la dernière ligne qui contient "token"
    local last_line=$(echo "$output" | tail -n1)
    [ "$last_line" = "token" ]
}
