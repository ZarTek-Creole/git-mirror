#!/usr/bin/env bats
# test_interactive.bats - Tests unitaires pour le module interactif

load 'test_helper.bash'

@test "interactive_init initializes interactive module" {
    run interactive_init
    
    [ "$status" -eq 0 ]
}

@test "interactive_is_terminal detects interactive terminal" {
    # Mock terminal detection
    test() {
        if [ "$1" = "-t" ] && [ "$2" = "0" ]; then
            return 0
        fi
        return 1
    }
    
    run interactive_is_terminal
    
    [ "$status" -eq 0 ]
}

@test "interactive_is_terminal detects non-interactive terminal" {
    # Mock non-terminal
    test() {
        if [ "$1" = "-t" ] && [ "$2" = "0" ]; then
            return 1
        fi
        return 0
    }
    
    run interactive_is_terminal
    
    [ "$status" -eq 1 ]
}

@test "interactive_confirm returns default when auto-yes enabled" {
    export AUTO_YES=true
    
    run interactive_confirm "Test message" "y"
    
    [ "$status" -eq 0 ]
}

@test "interactive_confirm returns default when auto-yes enabled with n default" {
    export AUTO_YES=true
    
    run interactive_confirm "Test message" "n"
    
    [ "$status" -eq 1 ]
}

@test "interactive_confirm returns default when non-interactive" {
    export AUTO_YES=false
    
    # Mock non-terminal
    test() {
        if [ "$1" = "-t" ] && [ "$2" = "0" ]; then
            return 1
        fi
        return 0
    }
    
    run interactive_confirm "Test message" "y"
    
    [ "$status" -eq 0 ]
}

@test "interactive_show_summary displays operation summary" {
    run interactive_show_summary "users" "testuser" "/tmp/repos" 100 5000 5 true true "token"
    
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Contexte           : users" ]]
    [[ "$output" =~ "Utilisateur/Org    : testuser" ]]
    [[ "$output" =~ "Destination        : /tmp/repos" ]]
    [[ "$output" =~ "Nombre de dépôts   : 100 repos" ]]
}

@test "interactive_confirm_start shows summary and asks for confirmation" {
    export AUTO_YES=true
    
    run interactive_confirm_start "users" "testuser" "/tmp/repos" 100 5000 5 true true "token"
    
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Résumé de l'Opération Git Mirror" ]]
}

@test "interactive_confirm_start returns false when user cancels" {
    export AUTO_YES=false
    
    # Mock non-terminal
    test() {
        if [ "$1" = "-t" ] && [ "$2" = "0" ]; then
            return 1
        fi
        return 0
    }
    
    # Mock read to return "n"
    read() {
        echo "n"
    }
    
    run interactive_confirm_start "users" "testuser" "/tmp/repos" 100 5000 5 true true "token"
    
    [ "$status" -eq 1 ]
}

@test "interactive_select_repos returns all repos when interactive disabled" {
    export INTERACTIVE_MODE=false
    
    local repos_json='[{"name": "repo1"}, {"name": "repo2"}]'
    
    run interactive_select_repos "$repos_json"
    
    [ "$status" -eq 0 ]
    [ "$output" = "$repos_json" ]
}

@test "interactive_select_repos returns all repos when non-terminal" {
    export INTERACTIVE_MODE=true
    
    # Mock non-terminal
    test() {
        if [ "$1" = "-t" ] && [ "$2" = "0" ]; then
            return 1
        fi
        return 0
    }
    
    local repos_json='[{"name": "repo1"}, {"name": "repo2"}]'
    
    run interactive_select_repos "$repos_json"
    
    [ "$status" -eq 0 ]
    [ "$output" = "$repos_json" ]
}

@test "interactive_select_repos uses fzf when available" {
    export INTERACTIVE_MODE=true
    
    # Mock terminal
    test() {
        if [ "$1" = "-t" ] && [ "$2" = "0" ]; then
            return 0
        fi
        return 1
    }
    
    # Mock fzf
    fzf() {
        echo "repo1 - Description"
    }
    
    local repos_json='[{"name": "repo1", "description": "Description"}, {"name": "repo2"}]'
    
    run interactive_select_repos "$repos_json"
    
    [ "$status" -eq 0 ]
    [[ "$output" =~ "repo1" ]]
}

@test "interactive_select_repos uses simple menu when fzf not available" {
    export INTERACTIVE_MODE=true
    
    # Mock terminal
    test() {
        if [ "$1" = "-t" ] && [ "$2" = "0" ]; then
            return 0
        fi
        return 1
    }
    
    # Mock fzf failure
    fzf() {
        return 1
    }
    
    # Mock read to select option "a" (all)
    read() {
        echo "a"
    }
    
    local repos_json='[{"name": "repo1"}, {"name": "repo2"}]'
    
    run interactive_select_repos "$repos_json"
    
    [ "$status" -eq 0 ]
    [ "$output" = "$repos_json" ]
}

@test "interactive_show_progress displays progress bar" {
    export INTERACTIVE_MODE=true
    
    # Mock terminal
    test() {
        if [ "$1" = "-t" ] && [ "$2" = "0" ]; then
            return 0
        fi
        return 1
    }
    
    run interactive_show_progress 50 100 "Traitement"
    
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Traitement" ]]
    [[ "$output" =~ "50%" ]]
    [[ "$output" =~ "50/100" ]]
}

@test "interactive_show_progress does nothing when non-interactive" {
    export INTERACTIVE_MODE=true
    
    # Mock non-terminal
    test() {
        if [ "$1" = "-t" ] && [ "$2" = "0" ]; then
            return 1
        fi
        return 0
    }
    
    run interactive_show_progress 50 100 "Traitement"
    
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "interactive_confirm_continue asks for confirmation on error" {
    export AUTO_YES=true
    
    run interactive_confirm_continue "Test error message"
    
    [ "$status" -eq 0 ]
}

@test "interactive_confirm_continue returns false when user cancels" {
    export AUTO_YES=false
    
    # Mock non-terminal
    test() {
        if [ "$1" = "-t" ] && [ "$2" = "0" ]; then
            return 1
        fi
        return 0
    fi
    
    # Mock read to return "n"
    read() {
        echo "n"
    }
    
    run interactive_confirm_continue "Test error message"
    
    [ "$status" -eq 1 ]
}

@test "interactive_setup initializes interactive module" {
    export INTERACTIVE_MODE=true
    export CONFIRM_MODE=true
    export AUTO_YES=false
    
    run interactive_setup
    
    [ "$status" -eq 0 ]
}
