# Makefile pour git-mirror
# Facilite l'installation, les tests et la maintenance

# Variables
PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin
MANDIR ?= $(PREFIX)/share/man/man1
CONFDIR ?= /etc/git-mirror
VERSION ?= 2.0.0

# Couleurs pour l'affichage
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[0;33m
BLUE := \033[0;34m
NC := \033[0m # No Color

.PHONY: all install uninstall test clean docs help act-test act-list act-quick act-workflow

# Cible par défaut
all: test

# Installation du script
install: install-script install-config install-docs
	@echo "$(GREEN)Installation terminée avec succès$(NC)"
	@echo "Pour utiliser git-mirror, ajoutez $(BINDIR) à votre PATH"

# Installation du script principal
install-script:
	@echo "$(BLUE)Installation du script principal...$(NC)"
	@mkdir -p $(BINDIR)
	@cp git-mirror.sh $(BINDIR)/git-mirror
	@chmod +x $(BINDIR)/git-mirror
	@echo "$(GREEN)Script installé dans $(BINDIR)/git-mirror$(NC)"

# Installation de la configuration
install-config:
	@echo "$(BLUE)Installation de la configuration...$(NC)"
	@mkdir -p $(CONFDIR)
	@cp config/git-mirror.conf $(CONFDIR)/
	@echo "$(GREEN)Configuration installée dans $(CONFDIR)/$(NC)"

# Installation de la documentation
install-docs:
	@echo "$(BLUE)Installation de la documentation...$(NC)"
	@mkdir -p $(MANDIR)
	@if [ -f docs/git-mirror.1 ]; then \
		cp docs/git-mirror.1 $(MANDIR)/; \
		echo "$(GREEN)Page man installée dans $(MANDIR)/$(NC)"; \
	fi

# Désinstallation
uninstall:
	@echo "$(YELLOW)Désinstallation de git-mirror...$(NC)"
	@rm -f $(BINDIR)/git-mirror
	@rm -f $(CONFDIR)/git-mirror.conf
	@rm -f $(MANDIR)/git-mirror.1
	@echo "$(GREEN)Désinstallation terminée$(NC)"

# Tests unitaires
test: test-shellcheck test-bats test-integration
	@echo "$(GREEN)Tous les tests sont passés avec succès$(NC)"

# Test avec shellcheck
test-shellcheck:
	@echo "$(BLUE)Exécution de shellcheck...$(NC)"
	@if command -v shellcheck >/dev/null 2>&1; then \
		shellcheck git-mirror.sh lib/*/*.sh config/*.sh; \
		echo "$(GREEN)ShellCheck: Aucun problème détecté$(NC)"; \
	else \
		echo "$(YELLOW)ShellCheck non disponible, installation...$(NC)"; \
		if command -v apt-get >/dev/null 2>&1; then \
			sudo apt-get update && sudo apt-get install -y shellcheck; \
		elif command -v yum >/dev/null 2>&1; then \
			sudo yum install -y shellcheck; \
		elif command -v brew >/dev/null 2>&1; then \
			brew install shellcheck; \
		else \
			echo "$(RED)Impossible d'installer shellcheck$(NC)"; \
			exit 1; \
		fi; \
		shellcheck git-mirror.sh lib/*/*.sh config/*.sh; \
		echo "$(GREEN)ShellCheck: Aucun problème détecté$(NC)"; \
	fi

# Tests unitaires avec bats
test-bats:
	@echo "$(BLUE)Exécution des tests unitaires...$(NC)"
	@if command -v bats >/dev/null 2>&1; then \
		bats tests/; \
		echo "$(GREEN)Tests unitaires: Tous passés$(NC)"; \
	else \
		echo "$(YELLOW)Bats non disponible, installation...$(NC)"; \
		if command -v npm >/dev/null 2>&1; then \
			npm install -g bats; \
		elif command -v apt-get >/dev/null 2>&1; then \
			sudo apt-get update && sudo apt-get install -y bats; \
		else \
			echo "$(RED)Impossible d'installer bats$(NC)"; \
			exit 1; \
		fi; \
		bats tests/; \
		echo "$(GREEN)Tests unitaires: Tous passés$(NC)"; \
	fi

# Tests d'intégration
test-integration:
	@echo "$(BLUE)Exécution des tests d'intégration...$(NC)"
	@if [ -f tests/integration/test_integration.sh ]; then \
		bash tests/integration/test_integration.sh; \
		echo "$(GREEN)Tests d'intégration: Tous passés$(NC)"; \
	else \
		echo "$(YELLOW)Aucun test d'intégration trouvé$(NC)"; \
	fi

# Tests de charge
test-load:
	@echo "$(BLUE)Exécution des tests de charge...$(NC)"
	@if [ -f tests/load/test_load.sh ]; then \
		bash tests/load/test_load.sh; \
		echo "$(GREEN)Tests de charge: Terminés$(NC)"; \
	else \
		echo "$(YELLOW)Aucun test de charge trouvé$(NC)"; \
	fi

# Nettoyage
clean:
	@echo "$(BLUE)Nettoyage des fichiers temporaires...$(NC)"
	@rm -rf .git-mirror-cache/
	@rm -f .git-mirror-state.json
	@rm -rf .git-mirror-state/
	@rm -f *.log
	@rm -f test-results/
	@echo "$(GREEN)Nettoyage terminé$(NC)"

# Génération de la documentation
docs: docs-man docs-readme
	@echo "$(GREEN)Documentation générée$(NC)"

# Génération de la page man
docs-man:
	@echo "$(BLUE)Génération de la page man...$(NC)"
	@mkdir -p docs/
	@if [ -f docs/git-mirror.1.md ]; then \
		pandoc docs/git-mirror.1.md -s -t man -o docs/git-mirror.1; \
		echo "$(GREEN)Page man générée$(NC)"; \
	else \
		echo "$(YELLOW)Source de la page man non trouvée$(NC)"; \
	fi

# Génération du README
docs-readme:
	@echo "$(BLUE)Génération du README...$(NC)"
	@if [ -f docs/README.md ]; then \
		cp docs/README.md README.md; \
		echo "$(GREEN)README généré$(NC)"; \
	else \
		echo "$(YELLOW)Source du README non trouvée$(NC)"; \
	fi

# Validation de la documentation
validate-docs:
	@echo "$(BLUE)Validation de la documentation...$(NC)"
	@if command -v markdownlint >/dev/null 2>&1; then \
		markdownlint README.md docs/*.md; \
		echo "$(GREEN)Documentation validée$(NC)"; \
	else \
		echo "$(YELLOW)markdownlint non disponible$(NC)"; \
	fi

# Package pour distribution
package:
	@echo "$(BLUE)Création du package...$(NC)"
	@mkdir -p dist/
	@tar -czf dist/git-mirror-$(VERSION).tar.gz \
		--exclude='.git' \
		--exclude='.git-mirror-cache' \
		--exclude='.git-mirror-state*' \
		--exclude='dist' \
		--exclude='test-results' \
		.
	@echo "$(GREEN)Package créé: dist/git-mirror-$(VERSION).tar.gz$(NC)"

# Installation des dépendances
install-deps:
	@echo "$(BLUE)Installation des dépendances...$(NC)"
	@if command -v apt-get >/dev/null 2>&1; then \
		sudo apt-get update && sudo apt-get install -y jq parallel git curl; \
	elif command -v yum >/dev/null 2>&1; then \
		sudo yum install -y jq parallel git curl; \
	elif command -v brew >/dev/null 2>&1; then \
		brew install jq parallel git curl; \
	else \
		echo "$(RED)Impossible d'installer les dépendances$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)Dépendances installées$(NC)"

# Aide
help:
	@echo "$(BLUE)Git Mirror - Makefile$(NC)"
	@echo ""
	@echo "$(GREEN)Commandes disponibles:$(NC)"
	@echo "  make install      - Installer git-mirror"
	@echo "  make uninstall    - Désinstaller git-mirror"
	@echo "  make test         - Exécuter tous les tests"
	@echo "  make test-shellcheck - Test avec shellcheck"
	@echo "  make test-bats    - Tests unitaires avec bats"
	@echo "  make test-integration - Tests d'intégration"
	@echo "  make test-load    - Tests de charge"
	@echo "  make clean        - Nettoyer les fichiers temporaires"
	@echo "  make docs         - Générer la documentation"
	@echo "  make package      - Créer un package de distribution"
	@echo "  make install-deps - Installer les dépendances"
	@echo "  make act-test     - Tester workflows GitHub Actions (actvement)"
	@echo "  make act-list     - Lister tous les workflows"
	@echo "  make act-quick    - Test rapide (ShellCheck)"
	@echo "  make act-workflow - Test un workflow (õORKFLOW=nom)"
	@echo "  make help         - Afficher cette aide"
	@echo ""
	@echo "$(GREEN)Variables:$(NC)"
	@echo "  PREFIX=$(PREFIX)"
	@echo "  BINDIR=$(BINDIR)"
	@echo "  MANDIR=$(MANDIR)"
	@echo "  CONFDIR=$(CONFDIR)"
	@echo "  VERSION=$(VERSION)"
# Act - GitHub Actions Testing

# Targets pour Act (GitHub Actions testing)
act-test:
	@echo "Test des workflows GitHub Actions localement..."
	@./scripts/test-workflows-local.sh --quick

act-list:
	@echo "Liste des workflows disponibles:"
	@./scripts/test-workflows-local.sh --list

act-quick:
	@echo "Test rapide: ShellCheck workflow..."
	@./scripts/test-workflows-local.sh --quick

act-workflow:
	@echo "Usage: make act-workflow WORKFLOW=shellcheck"
	@if [ -z "$(WORKFLOW)" ]; then \
		echo "Spécifiez WORKFLOW=nom_du_workflow"; \
		exit 1; \
	fi
	@./scripts/test-workflows-local.sh --workflow $(WORKFLOW)

