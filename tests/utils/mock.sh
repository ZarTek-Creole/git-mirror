#!/bin/bash
# Fonctions utilitaires pour les tests avec mocks GitHub

# Fonction pour charger un fichier JSON de mock
mock_api_response() {
    local mock_file="$1"
    
    if [ ! -f "$mock_file" ]; then
        echo "Error: Mock file not found: $mock_file" >&2
        return 1
    fi
    
    # Retourner le contenu du fichier JSON
    cat "$mock_file"
}

# Fonction pour créer un mock curl qui retourne un fichier JSON
mock_curl_with_file() {
    local mock_file="$1"
    local http_code="${2:-200}"
    
    curl() {
        local json_content
        if [ -f "$mock_file" ]; then
            json_content=$(cat "$mock_file")
        else
            json_content="{}"
        fi
        echo "${json_content}${http_code}"
        return 0
    }
}

# Fonction pour créer un mock curl qui retourne du JSON inline
mock_curl_with_json() {
    local json_content="$1"
    local http_code="${2:-200}"
    
    curl() {
        echo "${json_content}${http_code}"
        return 0
    }
}

# Fonction pour créer un mock curl qui simule une pagination
mock_curl_with_pagination() {
    local page1_json="$1"
    local page2_json="${2:-[]}"
    local per_page="${3:-100}"
    
    local page_count=0
    
    curl() {
        case "$*" in
            *"page=1"*|*"page=2"*|*page=1*)
                page_count=$((page_count + 1))
                if [ "$page_count" -eq 1 ]; then
                    echo "${page1_json}200"
                else
                    echo "${page2_json}200"
                fi
                ;;
            *)
                echo "[]200"
                ;;
        esac
        return 0
    }
}

# Fonction pour créer un mock curl qui simule des erreurs
mock_curl_with_error() {
    local error_message="$1"
    local http_code="${2:-403}"
    
    curl() {
        echo "{\"message\": \"${error_message}\"}${http_code}"
        return 0
    }
}

# Fonction pour créer un mock curl qui retourne une réponse vide
mock_curl_with_empty() {
    curl() {
        echo ""
        return 1
    }
}

# Fonction pour configurer l'environnement de test avec mocks
setup_test_environment() {
    local test_cache_dir="${TEST_CACHE_DIR:-/tmp/test-api-cache}"
    
    # Créer le répertoire de cache
    mkdir -p "$test_cache_dir"
    
    # Exporter les variables d'environnement de test
    export TEST_CACHE_DIR="$test_cache_dir"
    export API_CACHE_DIR="$test_cache_dir"
    export API_CACHE_TTL=3600
    export GITHUB_AUTH_METHOD="public"
    
    # Désactiver les logs pour les tests
    export QUIET=true
    export VERBOSE=0
}

# Fonction pour nettoyer l'environnement de test
cleanup_test_environment() {
    local test_cache_dir="${TEST_CACHE_DIR:-/tmp/test-api-cache}"
    
    # Supprimer le répertoire de cache
    rm -rf "$test_cache_dir"
    
    # Supprimer les fichiers de cache
    rm -f "$test_cache_dir"/*.json
    
    # Reset des variables
    unset TEST_CACHE_DIR
    unset API_CACHE_DIR
}

# Fonction pour obtenir un fichier JSON de mock GitHub
get_github_mock() {
    local endpoint="$1"
    local mock_file="tests/mocks/github/${endpoint}.json"
    
    if [ -f "$mock_file" ]; then
        echo "$mock_file"
    else
        echo "Error: Mock file not found for endpoint: $endpoint" >&2
        return 1
    fi
}

# Fonction pour vérifier si un fichier JSON de mock existe
mock_file_exists() {
    local endpoint="$1"
    local mock_file="tests/mocks/github/${endpoint}.json"
    
    [ -f "$mock_file" ]
}
