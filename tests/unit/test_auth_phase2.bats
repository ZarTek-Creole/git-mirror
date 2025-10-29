#!/usr/bin/env bats
# test_auth_phase2.bats - Tests unitaires Phase 2 pour le module d'authentification

load 'test_helper.bash'

@test "auth_validate_token supports modern token formats" {
    # Test token moderne ghp_
    export GITHUB_TOKEN="ghp_123456789012345678901234567890123456"
    
    # Mock successful API call
    curl() {
        echo '{"login": "testuser", "id": 12345}'
        return 0
    }
    
    run auth_validate_token "$GITHUB_TOKEN"
    
    [ "$status" -eq 0 ]
}

@test "auth_validate_token supports gho token format" {
    # Test token gho_
    export GITHUB_TOKEN="gho_123456789012345678901234567890123456"
    
    # Mock successful API call
    curl() {
        echo '{"login": "testuser", "id": 12345}'
        return 0
    }
    
    run auth_validate_token "$GITHUB_TOKEN"
    
    [ "$status" -eq 0 ]
}

@test "auth_validate_token supports ghu token format" {
    # Test token ghu_
    export GITHUB_TOKEN="ghu_123456789012345678901234567890123456"
    
    # Mock successful API call
    curl() {
        echo '{"login": "testuser", "id": 12345}'
        return 0
    }
    
    run auth_validate_token "$GITHUB_TOKEN"
    
    [ "$status" -eq 0 ]
}

@test "auth_validate_token supports ghs token format" {
    # Test token ghs_
    export GITHUB_TOKEN="ghs_123456789012345678901234567890123456"
    
    # Mock successful API call
    curl() {
        echo '{"login": "testuser", "id": 12345}'
        return 0
    }
    
    run auth_validate_token "$GITHUB_TOKEN"
    
    [ "$status" -eq 0 ]
}

@test "auth_validate_token supports ghr token format" {
    # Test token ghr_
    export GITHUB_TOKEN="ghr_123456789012345678901234567890123456"
    
    # Mock successful API call
    curl() {
        echo '{"login": "testuser", "id": 12345}'
        return 0
    }
    
    run auth_validate_token "$GITHUB_TOKEN"
    
    [ "$status" -eq 0 ]
}

@test "auth_validate_token rejects invalid modern token format" {
    # Test token moderne invalide
    export GITHUB_TOKEN="ghp_invalid_token_format"
    
    run auth_validate_token "$GITHUB_TOKEN"
    
    [ "$status" -eq 1 ]
}

@test "auth_validate_token handles API validation failure" {
    export GITHUB_TOKEN="1234567890123456789012345678901234567890"
    
    # Mock failed API call
    curl() {
        echo '{"message": "Bad credentials"}'
        return 0
    }
    
    run auth_validate_token "$GITHUB_TOKEN"
    
    [ "$status" -eq 1 ]
}

@test "auth_validate_token handles network error" {
    export GITHUB_TOKEN="1234567890123456789012345678901234567890"
    
    # Mock network error
    curl() {
        return 1
    }
    
    run auth_validate_token "$GITHUB_TOKEN"
    
    [ "$status" -eq 1 ]
}

@test "auth_detect_method validates token before using it" {
    export GITHUB_TOKEN="1234567890123456789012345678901234567890"
    
    # Mock failed token validation
    curl() {
        echo '{"message": "Bad credentials"}'
        return 0
    }
    
    run auth_detect_method
    
    [ "$status" -eq 0 ]
    # Extraire la dernière ligne qui contient "public"
    local last_line=$(echo "$output" | tail -n1)
    [ "$last_line" = "public" ]
}

@test "auth_detect_method forces token method when GITHUB_AUTH_METHOD=token" {
    export GITHUB_TOKEN="1234567890123456789012345678901234567890"
    export GITHUB_AUTH_METHOD="token"
    
    # Mock successful API call
    curl() {
        echo '{"login": "testuser", "id": 12345}'
        return 0
    }
    
    run auth_detect_method
    
    [ "$status" -eq 0 ]
    # Extraire la dernière ligne qui contient "token"
    local last_line=$(echo "$output" | tail -n1)
    [ "$last_line" = "token" ]
}

@test "auth_detect_method fails when token method forced but no token" {
    unset GITHUB_TOKEN
    export GITHUB_AUTH_METHOD="token"
    
    run auth_detect_method
    
    [ "$status" -eq 1 ]
}

@test "auth_detect_method forces ssh method when GITHUB_AUTH_METHOD=ssh" {
    unset GITHUB_TOKEN
    export GITHUB_AUTH_METHOD="ssh"
    
    # Mock SSH failure (should still return ssh when forced)
    ssh() {
        echo "Permission denied (publickey)."
        return 1
    }
    
    run auth_detect_method
    
    [ "$status" -eq 0 ]
    [ "$output" = "ssh" ]
}

@test "auth_detect_method forces public method when GITHUB_AUTH_METHOD=public" {
    export GITHUB_TOKEN="1234567890123456789012345678901234567890"
    export GITHUB_AUTH_METHOD="public"
    
    run auth_detect_method
    
    [ "$status" -eq 0 ]
    # Extraire la dernière ligne qui contient "public"
    local last_line=$(echo "$output" | tail -n1)
    [ "$last_line" = "public" ]
}

@test "auth_detect_method rejects invalid auth method" {
    export GITHUB_AUTH_METHOD="invalid_method"
    
    run auth_detect_method
    
    [ "$status" -eq 1 ]
}
