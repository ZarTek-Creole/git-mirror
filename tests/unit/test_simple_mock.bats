#!/usr/bin/env bats

load 'test_helper.bash'

@test "simple mock test for api_fetch_all_repos" {
    # Configuration de l'environnement de test
    setup_test_environment
    
    # Créer un mock curl simple qui retourne le JSON du fichier mock
    curl() {
        local json_content
        json_content=$(cat tests/mocks/github/repos.json)
        echo "${json_content}200"
        return 0
    }
    
    export -f curl
    
    # Tester la récupération des dépôts
    run api_fetch_all_repos "users" "testuser"
    
    [ "$status" -eq 0 ]
    
    # Extraire le JSON multiligne (de [ à ])
    local json_output=$(echo "$output" | sed -n '/^\[/,/^\]/p')
    
    # Vérifier que le JSON est valide et a au moins 2 dépôts
    local repo_count=$(echo "$json_output" | jq 'length')
    [ "$repo_count" -ge 2 ]
    
    # Nettoyer
    cleanup_test_environment
}
