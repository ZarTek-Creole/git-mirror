# git-mirror
## Résumé
Ce script permet de mettre à jour tous les dépôts d'un utilisateur ou d'une organisation sur GitHub. Il utilise l'API GitHub et l'outil jq pour récupérer la liste des dépôts et exécute la commande git clone ou git pull sur chaque dépôt.

## Description
Ce script permet de cloner ou mettre à jour tous les dépôts GitHub (qui ne sont pas des forks) appartenant à un utilisateur ou une organisation donnée. Il utilise l'API GitHub et l'outil jq pour récupérer la liste des dépôts et exécute la commande git clone ou git pull sur chaque dépôt. Le script définit également un délai d'expiration de 30 secondes pour la commande git afin d'éviter les exécutions de commandes interminables.


## Dépendances & Prérequis
Pour utiliser ce script, vous devez avoir les outils suivants installés sur votre ordinateur :
- jq (version 1.5 ou supérieure) : outil de manipulation de JSON en ligne de commande. Vous pouvez l'installer en exécutant la commande suivante :
  - Ubuntu/Debian : `sudo apt-get install jq`
  - CentOS/Fedora : `sudo yum install jq`
  - MacOS : `brew install jq`
  - Si aucun de ces gestionnaires de paquets n'est disponible, vous pouvez télécharger l'archive de jq depuis le site officiel (https://stedolan.github.io/jq/) et l'installer manuellement.
- git (version 2.9 ou supérieure) : outil de gestion de versions. Vous pouvez l'installer en exécutant la commande suivante :
  - Ubuntu/Debian : `sudo apt-get install git`
  - CentOS/Fedora : `sudo yum install git`
  - MacOS : `brew install git`
  - Si aucun de ces gestionnaires de paquets n'est disponible, vous pouvez télécharger l'installateur de git depuis le site officiel (https://git-scm.com/downloads) et l'exécuter.
-  curl : outil de téléchargement de fichiers en ligne de commande. Vous pouvez l'installer en exécutant la commande suivante :
  - Ubuntu/Debian : sudo apt-get install curl
  - CentOS/Fedora : sudo yum install curl
  - MacOS : brew install curl
  - Si aucun de ces gestionnaires de paquets n'est disponible, vous pouvez télécharger l'archive de curl depuis le site officiel (https://curl.haxx.se/download.html) et l'installer manuellement. Le script utilise également cURL pour envoyer des requêtes HTTP à l'API GitHub. Si cURL n'est pas installé sur votre ordinateur, le script ne fonctionnera pas.

## Utilisation
1. Téléchargez le script sur votre ordinateur
2. Ouvrez un terminal et rendez-vous dans le répertoire où se trouve le script
3. Exécutez la commande suivante : `./nom_du_script.sh context username_or_orgname`
   Exemple : pour mettre à jour tous les dépôts de l'utilisateur ZarTek-Creole, exécutez la commande suivante : `./nom_du_script.sh users ZarTek-Creole`
    La commande prend deux arguments :
  * **context** : le contexte dans lequel se trouve le nom d'utilisateur ou d'organisation. Peut être soit "users" pour les utilisateurs, soit "orgs" pour les organisations.
  * **username_or_orgname** : le nom d'utilisateur ou d'organisation dont vous souhaitez cloner ou mettre à jour les dépôts.
# Limitations
- Ce script ne fonctionne que pour les dépôts qui ne sont pas des forks. Si vous souhaitez inclure les forks dans la mise à jour, vous devrez enlever l'option &parent=null de la requête API.
- Le script utilise l'API GitHub, qui a une limite de requêtes par heure. Si vous avez un grand nombre de dépôts, il se peut que vous atteigniez cette limite et que le script ne puisse pas terminer son exécution. Vous pouvez contourner ce problème en utilisant un token d'accès à l'API GitHub, qui vous permet d'avoir un nombre de requêtes plus élevé.
- Le script ignore les dépôts dont le nom commence par un point (.). Si vous souhaitez inclure ces dépôts, vous pouvez supprimer la ligne `if [[ $repo_name =~ ^\. ]];` then dans la fonction `clone_or_update_repo`.
- Il définit un délai d'expiration de 30 secondes pour la commande git afin d'éviter les exécutions de commandes interminables. Si une commande git prend plus de 30 secondes à s'exécuter, le script affichera un message d'erreur et passer à l'itération suivante. Le délai d'expiration de 30 secondes pour la commande git peut être modifié en modifiant la valeur de timeout dans le script.
# Options de configuration
Vous pouvez modifier la valeur de `timeout` pour définir le temps maximum d'exécution de la commande `git`. Si la commande dépasse ce temps, un message d'erreur sera affiché.
Vous pouvez ajouter des options à la commande `git clon`e ou `git pull` en modifiant la fonction `clone_or_update_repo`.

### Exemples de commandes
Voici quelques exemples de commandes qui vous permettront de mettre à jour les dépôts GitHub d'un utilisateur ou d'une organisation :

- Mettre à jour tous les dépôts de l'utilisateur "ZarTek-Creole" :
```/nom_du_script.sh users ZarTek-Creole```
- Mettre à jour tous les dépôts de l'organisation "openai" :
```./nom_du_script.sh organizations openai```
- Mettre à jour tous les dépôts de l'utilisateur "ZarTek-Creole" en utilisant un délai d'expiration de 60 secondes pour la commande git :
```timeout=60 ./nom_du_script.sh users ZarTek-Creole```
Vous pouvez également utiliser ces exemples de commandes en modifiant les arguments `context` et `username_or_orgname` selon vos besoins. N'oubliez pas de remplacer `nom_du_script.sh` par le nom de fichier du script téléchargé.




## Notes
Le script ignore les dépôts dont le nom commence par un point (`.`).
Si le *dépôt existe* déjà sur votre ordinateur, la commande `git pull` sera exécutée pour *mettre à jour* le dépôt. Sinon, la commande `git clone` sera exécutée pour *télécharger* le dépôt.
## Contributions
Ce projet est ouvert aux contributions de tous types ! Si vous souhaitez contribuer, voici quelques idées de choses à faire :

### Améliorer la documentation
- Ajouter de nouvelles fonctionnalités au script
- Corriger des bugs ou améliorer la stabilité du script
- Traduire la documentation dans d'autres langues
- ...
### Comment contribuer
Pour contribuer, voici les étapes à suivre :

- Faites un fork du projet sur votre compte GitHub.
- Créez une branche pour votre contribution (par exemple, fix-typo-in-readme).
- Faites vos changements dans votre branche et committez-les.
- Poussez votre branche sur votre fork du projet.
- Créez une pull request depuis votre branche vers la branche master du projet principal.
- N'hésitez pas à nous contacter ou à ouvrir une issue si vous avez des questions ou des idées de contributions !

## Problèmes courants et solutions connues
Voici quelques problèmes courants que les utilisateurs peuvent rencontrer lors de l'utilisation de ce script et les solutions connues :

- Erreur : "jq: command not found" : Cette erreur signifie que l'outil jq n'est pas installé sur votre ordinateur. Pour résoudre ce problème, veuillez suivre les instructions d'installation dans la section "Dépendances" du README.
- Erreur : "git: command not found" : Cette erreur signifie que l'outil git n'est pas installé sur votre ordinateur. Pour résoudre ce problème, veuillez suivre les instructions d'installation dans la section "Dépendances" du README.
- Erreur : "Error: git command took too long to execute" : Cette erreur signifie que la commande git a dépassé le délai d'expiration de 30 secondes. Pour résoudre ce problème, vous pouvez essayer d'augmenter la valeur de timeout dans le script ou exécuter la commande git directement depuis votre terminal pour obtenir plus de détails sur l'erreur.
- Erreur : "Error: Invalid context" : Cette erreur signifie que le contexte spécifié (utilisateurs ou organisations) n'est pas valide. Veuillez vous assurer que vous avez spécifié "users" ou "orgs" comme premier argument de la ligne de commande.
- Erreur : "Error: Repository not found" : Cette erreur signifie que le nom d'utilisateur ou d'organisation spécifié n'a pas été trouvé sur GitHub. Veuillez vous assurer que vous avez entré le nom correctement et que l'utilisateur ou l'organisation existe bien sur GitHub.
- Si vous rencontrez un autre problème qui n'est pas mentionné ci-dessus, veuillez ouvrir une issue sur notre page de dépôt GitHub (https://github.com/ZarTek-Creole/git-mirror/issues) pour obtenir de l'aide. N'hésitez pas à inclure des détails sur l'erreur que vous avez rencontrée et les étapes que vous avez suivies pour reproduire l'erreur. Nous ferons de notre mieux pour vous aider à résoudre le problème le plus rapidement possible.

## Licence
Ce projet est sous licence MIT - voir le fichier de licence pour plus de détails.

La licence MIT est une licence de logiciel libre très couramment utilisée. Elle permet à quiconque de librement utiliser, copier, modifier et redistribuer le logiciel, même à des fins commerciales, sous réserve de citer la source et de ne pas utiliser le nom de l'auteur à des fins de promotion.

En utilisant ce projet, vous acceptez les termes de la licence MIT et vous vous engagez à respecter ses conditions. Si vous avez des questions sur la licence ou sur les droits qui vous sont accordés en tant qu'utilisateur, n'hésitez pas à nous contacter ou à consulter la documentation de la licence MIT.

# Donations
Nous sommes très reconnaissants pour toute contribution à notre projet. Si vous souhaitez soutenir notre travail et aider à financer les développements futurs, vous pouvez faire un don via PayPal ou une autre plateforme de paiement en ligne. Vous trouverez les détails pour faire un don sur notre page de don (https://github.com/ZarTek-Creole/DONATE).

Le développement open source est crucial pour l'innovation et la croissance de l'industrie de la technologie. En faisant un don, vous pouvez contribuer à la vitalité de l'écosystème open source et soutenir les développeurs qui travaillent dur pour créer des outils utiles et innovants.

Nous sommes reconnaissants pour tout soutien, qu'il soit financier ou en termes de temps et de compétences. Votre contribution est précieuse pour nous et nous espérons que nos projets continueront à grandir grâce à votre soutien. Nous vous remercions de votre générosité et de votre soutien à notre projet !

Voici comment vous pouvez faire un don à notre projet via https://ko-fi.com/zartek :

- Visitez la page de don https://ko-fi.com/zartek
- Cliquez sur le bouton "Donate"
- Entrez le montant que vous souhaitez donner dans le champ "Amount" et sélectionnez votre devise
- Si vous avez un compte Ko-fi, connectez-vous pour continuer. Si vous n'avez pas de compte, vous pouvez vous en créer un ou continuer en tant qu'invité
- Sélectionnez votre méthode de paiement (PayPal, carte de crédit ou autre) et suivez les instructions pour finaliser votre don
- Nous sommes reconnaissants pour toute contribution et nous espérons que notre projet continuera à grandir grâce à votre soutien. ***Merci de votre générosité !***
