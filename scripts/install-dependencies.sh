#!/bin/bash
# Script d'installation des dépendances pour tests
# Utilisé dans les workflows réutilisables

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly SCRIPT_DIR

# Couleurs pour output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# Parse arguments
INSTALL_SHELLCHECK=false
INSTALL_BATS=false
INSTALL_KCOV=false
INSTALL_MARKDOWNLINT=false
INSTALL_PANDOC=false
INSTALL_SHELLSPEC=false
INSTALL_PARALLEL=true

usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Options:
  --shellcheck         Install ShellCheck
  --bats               Install Bats
  --kcov               Install kcov (Linux only)
  --markdownlint       Install markdownlint-cli
  --pandoc             Install Pandoc
  --shellspec          Install ShellSpec
  --no-parallel        Skip GNU parallel installation
  --help               Show this help message

Example:
  $0 --shellcheck --bats --parallel
EOF
    exit 1
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --shellcheck)
            INSTALL_SHELLCHECK=true
            shift
            ;;
        --bats)
            INSTALL_BATS=true
            shift
            ;;
        --kcov)
            INSTALL_KCOV=true
            shift
            ;;
        --markdownlint)
            INSTALL_MARKDOWNLINT=true
            shift
            ;;
        --pandoc)
            INSTALL_PANDOC=true
            shift
            ;;
        --shellspec)
            INSTALL_SHELLSPEC=true
            shift
            ;;
        --no-parallel)
            INSTALL_PARALLEL=false
            shift
            ;;
        --help)
            usage
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            usage
            ;;
    esac
done

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "darwin"
    else
        echo "unknown"
    fi
}

OS=$(detect_os)
readonly OS

echo -e "${GREEN}=== Git-Mirror Dependency Installation ===${NC}"
echo "OS: $OS"

# Install ShellCheck
install_shellcheck() {
    if [[ "$OS" == "linux" ]]; then
        echo -e "${YELLOW}Installing ShellCheck on Linux...${NC}"
        sudo apt-get update -qq
        sudo apt-get install -y shellcheck
    elif [[ "$OS" == "darwin" ]]; then
        echo -e "${YELLOW}Installing ShellCheck on macOS...${NC}"
        brew install shellcheck
    fi
    echo -e "${GREEN}✅ ShellCheck installed: $(shellcheck --version | head -1)${NC}"
}

# Install Bats with retry logic
install_bats() {
    echo -e "${YELLOW}Installing Bats via npm...${NC}"
    local retry=0
    local max_retries=3
    
    while [[ $retry -lt $max_retries ]]; do
        if npm install -g bats@latest; then
            echo -e "${GREEN}✅ Bats installed${NC}"
            return 0
        fi
        retry=$((retry + 1))
        echo -e "${YELLOW}Retry $retry/$max_retries...${NC}"
        sleep 5
    done
    
    echo -e "${RED}❌ Failed to install Bats after $max_retries attempts${NC}"
    return 1
}

# Install kcov (Linux only)
install_kcov() {
    if [[ "$OS" != "linux" ]]; then
        echo -e "${YELLOW}⚠️ kcov is Linux-only, skipping...${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}Building kcov from source...${NC}"
    sudo apt-get update -qq
    sudo apt-get install -y libcurl4-openssl-dev libelf-dev libdw-dev cmake gcc binutils-dev
    
    wget -q https://github.com/SimonKagstrom/kcov/archive/v38.tar.gz
    tar xzf v38.tar.gz
    cd kcov-38
    mkdir build && cd build
    cmake ..
    make -j"$(nproc)"
    sudo make install
    cd "$SCRIPT_DIR"
    
    echo -e "${GREEN}✅ kcov v38 installed${NC}"
}

# Install markdownlint
install_markdownlint() {
    echo -e "${YELLOW}Installing markdownlint-cli...${NC}"
    npm install -g markdownlint-cli@latest
    echo -e "${GREEN}✅ markdownlint installed${NC}"
}

# Install Pandoc
install_pandoc() {
    if [[ "$OS" == "linux" ]]; then
        sudo apt-get install -y pandoc
    elif [[ "$OS" == "darwin" ]]; then
        brew install pandoc
    fi
    echo -e "${GREEN}✅ Pandoc installed${NC}"
}

# Install ShellSpec
install_shellspec() {
    echo -e "${YELLOW}Installing ShellSpec...${NC}"
    curl -fsSL https://git.io/shellspec | sh -s -- --yes
    echo "$PWD/bin" >> "$GITHUB_PATH"
    echo -e "${GREEN}✅ ShellSpec installed${NC}"
}

# Install GNU parallel and basic dependencies
install_parallel() {
    if [[ "$OS" == "linux" ]]; then
        echo -e "${YELLOW}Installing system dependencies on Linux...${NC}"
        sudo apt-get update -qq
        sudo apt-get install -y jq parallel git curl bash
    elif [[ "$OS" == "darwin" ]]; then
        echo -e "${YELLOW}Installing system dependencies on macOS...${NC}"
        brew install jq parallel git curl bash
    fi
    echo -e "${GREEN}✅ System dependencies installed${NC}"
}

# Main installation logic
main() {
    if [[ "$INSTALL_PARALLEL" == "true" ]]; then
        install_parallel
    fi
    
    if [[ "$INSTALL_SHELLCHECK" == "true" ]]; then
        install_shellcheck
    fi
    
    if [[ "$INSTALL_BATS" == "true" ]]; then
        install_bats
    fi
    
    if [[ "$INSTALL_KCOV" == "true" ]]; then
        install_kcov
    fi
    
    if [[ "$INSTALL_MARKDOWNLINT" == "true" ]]; then
        install_markdownlint
    fi
    
    if [[ "$INSTALL_PANDOC" == "true" ]]; then
        install_pandoc
    fi
    
    if [[ "$INSTALL_SHELLSPEC" == "true" ]]; then
        install_shellspec
    fi
    
    echo ""
    echo -e "${GREEN}=== Installation Summary ===${NC}"
    echo -e "${GREEN}✅ All requested dependencies installed successfully${NC}"
}

main "$@"

