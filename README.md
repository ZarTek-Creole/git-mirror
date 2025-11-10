# Git Mirror

[![Version](https://img.shields.io/badge/version-2.5.0-orange)](CHANGELOG.md) [![License](https://img.shields.io/badge/license-MIT-blue)](LICENSE) [![Bash](https://img.shields.io/badge/bash-4.4%2B-green)](https://www.gnu.org/software/bash/) [![Issues](https://img.shields.io/github/issues/ZarTek-Creole/git-mirror)](https://github.com/ZarTek-Creole/git-mirror/issues) [![Stars](https://img.shields.io/github/stars/ZarTek-Creole/git-mirror)](https://github.com/ZarTek-Creole/git-mirror/stargazers)

> Advanced Bash script for GitHub repository backup, cloning, mirroring, synchronization, monitoring and export. Complete DevOps automation tool for Git repository management.

## Table des Matières

- [Résumé](#résumé)
- [Description](#description)
- [Caractéristiques principales](#caractéristiques-principales)
- [Dépendances & Prérequis](#dépendances--prérequis)
- [Utilisation](#utilisation)
- [Architecture du Projet](#architecture-du-projet)
- [Documentation](#documentation)
- [Matrice de Compatibilité](#matrice-de-compatibilité)
- [Notes importantes](#notes-importantes)
- [Limitations](#limitations)
- [Problèmes courants et solutions](#problèmes-courants-et-solutions)
- [Contributions](#contributions)
- [Licence](#licence)
- [Auteur](#auteur)
- [Donations](#donations)

## Résumé

Git Mirror est un script avancé permettant de cloner ou mettre à jour tous les dépôts GitHub d'un utilisateur ou d'une organisation. Il supporte l'authentification, le traitement parallèle, les filtres, et offre une large gamme d'options de configuration.

## Description

Ce script Bash permet de cloner ou mettre à jour tous les dépôts GitHub (avec ou sans forks selon vos préférences) appartenant à un utilisateur ou une organisation donnée. Il utilise l'API GitHub et l'outil jq pour récupérer la liste des dépôts et exécute la commande git clone ou git pull sur chaque dépôt. Le script définit également un délai d'expiration configurable pour la commande git afin d'éviter les exécutions de commandes interminables.

## Caractéristiques principales

- 🔐 **Authentification multiple** : Token GitHub, clé SSH, ou accès public
- ⚡ **Traitement parallèle** : Utilisation de GNU parallel pour accélérer les opérations
- 🔍 **Filtrage avancé** : Inclure/exclure des dépôts par patterns
- 📊 **Monitoring intégré** : Surveillance et rapports détaillés
- 🔄 **Synchronisation automatique** : Mise à jour automatique des dépôts existants
- 💾 **Backup intelligent** : Sauvegarde complète avec gestion des versions
- 🎯 **Configuration flexible** : Fichiers de configuration multiples
- 📝 **Logs détaillés** : Journalisation complète des opérations

## Quick Start

```bash
# Installation
git clone https://github.com/ZarTek-Creole/git-mirror.git
cd git-mirror

# Configuration
cp .secrets.example .secrets
# Edit .secrets with your GitHub token

# Utilisation basique
./git-mirror.sh --user USERNAME

# Utilisation avancée
./git-mirror.sh --org ORGANIZATION --parallel 4 --exclude-pattern "test-*"
```

## Documentation

Pour une documentation complète, consultez:
- [Documentation détaillée](docs/)
- [Guide d'utilisation](docs/USAGE.md)
- [Architecture du projet](docs/ARCHITECTURE.md)
- [Exemples de configuration](docs/EXAMPLES.md)

## Contributions

Les contributions sont les bienvenues! Consultez [CONTRIBUTING.md](CONTRIBUTING.md) pour plus d'informations.

## Licence

Ce projet est sous licence MIT. Voir [LICENSE](LICENSE) pour plus de détails.

## Auteur

**ZarTek-Creole**
- GitHub: [@ZarTek-Creole](https://github.com/ZarTek-Creole)
- Website: [https://github.com/ZarTek-Creole](https://github.com/ZarTek-Creole)

## Donations

Si vous trouvez ce projet utile, envisagez de faire un don:
- Ko-fi: [ko-fi.com/zartek](https://ko-fi.com/zartek)

---

## Keywords

`git` `github` `backup` `mirror` `clone` `synchronization` `devops` `automation` `bash` `shell-script` `repository-management` `git-tools` `ci-cd` `linux` `monitoring` `parallel-processing` `api` `github-api` `deployment` `version-control` `repository-sync` `github-backup` `git-automation` `open-source`
