#!/bin/bash
# Script de Benchmarking pour Git Mirror
# Description: Mesure les performances du script
# Usage: ./scripts/benchmark.sh [options]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
TEST_USER="${TEST_USER:-microsoft}"
TEST_ORG="${TEST_ORG:-microsoft}"
PARALLEL_JOBS="${PARALLEL_JOBS:-5}"
OUTPUT_FILE="${OUTPUT_FILE:-benchmark_results.txt}"

# Fonction d'aide
show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Benchmark Git Mirror Performance

Options:
  -u, --user USER      Utilisateur GitHub à tester (défaut: microsoft)
  -o, --org ORG        Organisation GitHub à tester (défaut: microsoft)
  -j, --jobs JOBS      Nombre de jobs parallèles (défaut: 5)
  -o, --output FILE    Fichier de sortie (défaut: benchmark_results.txt)
  -h, --help           Afficher cette aide

Exemples:
  $0                                    # Benchmark avec microsoft
  $0 -u octocat                         # Benchmark avec octocat
  $0 -j 10 -o results.txt               # 10 jobs parallèles, résultats dans results.txt

EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -u|--user)
            TEST_USER="$2"
            shift 2
            ;;
        -o|--org)
            TEST_ORG="$2"
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -j|--jobs)
            PARALLEL_JOBS="$2"
            shift 2
            ;;
        --output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Option inconnue: $1" >&2
            show_help
            exit 1
            ;;
    esac
done

# Header
echo "==========================================" > "$OUTPUT_FILE"
echo "Git Mirror Benchmark Results" >> "$OUTPUT_FILE"
echo "==========================================" >> "$OUTPUT_FILE"
echo "Date: $(date)" >> "$OUTPUT_FILE"
echo "OS: $(uname -a)" >> "$OUTPUT_FILE"
echo "Bash: $(bash --version | head -1)" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Test 1: Startup Time (sans aucune action)
echo -e "${BLUE}[1/5]${NC} Test du temps de démarrage..."
START_TIME=$(date +%s%N)
"$PROJECT_DIR/git-mirror.sh" --help > /dev/null 2>&1
END_TIME=$(date +%s%N)
STARTUP_MS=$(( (END_TIME - START_TIME) / 1000000 ))
echo "  ✓ Startup time: ${STARTUP_MS}ms" | tee -a "$OUTPUT_FILE"

# Test 2: Memory Usage (dry-run simple)
echo -e "${BLUE}[2/5]${NC} Test de la mémoire..."
MEM_START=$(free -m | awk 'NR==2{printf "%.1f", $3}')
"$PROJECT_DIR/git-mirror.sh" --dry-run -q users "$TEST_USER" > /dev/null 2>&1 || true
MEM_END=$(free -m | awk 'NR==2{printf "%.1f", $3}')
MEM_USED=$(echo "$MEM_END - $MEM_START" | bc)
echo "  ✓ Memory usage: ${MEM_USED}MB" | tee -a "$OUTPUT_FILE"

# Test 3: Sequential Operations
echo -e "${BLUE}[3/5]${NC} Test séquentiel..."
echo "" >> "$OUTPUT_FILE"
echo "Sequential Test (1 job):" >> "$OUTPUT_FILE"
SEQUENTIAL_START=$(date +%s)
"$PROJECT_DIR/git-mirror.sh" --dry-run -q users "$TEST_USER" --parallel 1 2>&1 | head -20 >> "$OUTPUT_FILE" || true
SEQUENTIAL_END=$(date +%s)
SEQUENTIAL_TIME=$((SEQUENTIAL_END - SEQUENTIAL_START))
echo "  ✓ Sequential time: ${SEQUENTIAL_TIME}s" | tee -a "$OUTPUT_FILE"

# Test 4: Parallel Operations
echo -e "${BLUE}[4/5]${NC} Test parallèle ($PARALLEL_JOBS jobs)..."
echo "" >> "$OUTPUT_FILE"
echo "Parallel Test ($PARALLEL_JOBS jobs):" >> "$OUTPUT_FILE"
PARALLEL_START=$(date +%s)
"$PROJECT_DIR/git-mirror.sh" --dry-run -q users "$TEST_USER" --parallel "$PARALLEL_JOBS" 2>&1 | head -20 >> "$OUTPUT_FILE" || true
PARALLEL_END=$(date +%s)
PARALLEL_TIME=$((PARALLEL_END - PARALLEL_START))
echo "  ✓ Parallel time: ${PARALLEL_TIME}s" | tee -a "$OUTPUT_FILE"

# Test 5: Git Operations Performance
echo -e "${BLUE}[5/5]${NC} Test des opérations Git..."
echo "" >> "$OUTPUT_FILE"
echo "Git Operations Test:" >> "$OUTPUT_FILE"
GIT_START=$(date +%s%N)
git --version > /dev/null 2>&1
GIT_END=$(date +%s%N)
GIT_TIME=$(( (GIT_END - GIT_START) / 1000000 ))
echo "  ✓ Git command time: ${GIT_TIME}ms" | tee -a "$OUTPUT_FILE"

# Summary
echo "" >> "$OUTPUT_FILE"
echo "==========================================" >> "$OUTPUT_FILE"
echo "Summary" >> "$OUTPUT_FILE"
echo "==========================================" >> "$OUTPUT_FILE"
echo "Startup time: ${STARTUP_MS}ms" >> "$OUTPUT_FILE"
echo "Memory usage: ${MEM_USED}MB" >> "$OUTPUT_FILE"
echo "Sequential time: ${SEQUENTIAL_TIME}s" >> "$OUTPUT_FILE"
echo "Parallel time (${PARALLEL_JOBS} jobs): ${PARALLEL_TIME}s" >> "$OUTPUT_FILE"

# Calculate speedup
if [ "$PARALLEL_TIME" -gt 0 ]; then
    SPEEDUP=$(echo "scale=2; $SEQUENTIAL_TIME / $PARALLEL_TIME" | bc)
    echo "Speedup: ${SPEEDUP}x" >> "$OUTPUT_FILE"
    echo -e "${GREEN}✓ Speedup: ${SPEEDUP}x${NC}"
fi

echo "" >> "$OUTPUT_FILE"
echo "Benchmark completed: $(date)" >> "$OUTPUT_FILE"

echo ""
echo -e "${GREEN}✓ Benchmark terminé !${NC}"
echo -e "Résultats sauvegardés dans: ${YELLOW}$OUTPUT_FILE${NC}"

# Print summary
echo ""
echo -e "${BLUE}=== Résumé des performances ===${NC}"
echo "Startup: ${STARTUP_MS}ms (target: <100ms)"
if [ "$STARTUP_MS" -lt 100 ]; then
    echo -e "${GREEN}✓✓✓ EXCELLENT${NC}"
elif [ "$STARTUP_MS" -lt 200 ]; then
    echo -e "${YELLOW}✓✓ BON${NC}"
else
    echo -e "${RED}✗ À AMÉLIORER${NC}"
fi

echo "Memory: ${MEM_USED}MB (target: <50MB)"
if (( $(echo "$MEM_USED < 50" | bc -l) )); then
    echo -e "${GREEN}✓✓✓ EXCELLENT${NC}"
elif (( $(echo "$MEM_USED < 100" | bc -l) )); then
    echo -e "${YELLOW}✓✓ BON${NC}"
else
    echo -e "${RED}✗ À AMÉLIORER${NC}"
fi

