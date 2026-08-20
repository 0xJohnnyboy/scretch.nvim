# Spec: Tests automatiques sur les pull requests

## 1. Meta

- Date : 2026-08-20
- Statut : Approved
- Portée : GitHub Actions

## 2. Contexte / Problème

Les pull requests ne lancent actuellement aucun test du plugin. GitGuardian est
le seul check visible et ne détecte pas les régressions fonctionnelles Lua.

## 3. Objectifs

- Exécuter la suite Lua sur chaque pull request.
- Permettre de lancer la même suite manuellement depuis GitHub Actions.
- Rendre le résultat bloquant et visible dans les checks GitHub.
- Garder le workflow rapide, déterministe et à permissions minimales.

## 4. Non-objectifs

- Tester plusieurs systèmes d'exploitation ou versions de Neovim.
- Déployer, publier des artefacts ou modifier le dépôt.
- Exécuter le workflow lors des push directs dans cette première version.

## 5. Scope

### In

- Workflow déclenché par `pull_request`.
- Déclenchement manuel sans paramètre via `workflow_dispatch`.
- Runner Ubuntu et version stable de Neovim.
- Checkout du code puis exécution de `tests/run.lua` en mode headless.
- Annulation d'une exécution obsolète pour la même pull request.

### Out

- Matrice multi-OS/multi-version.
- Couverture de code, cache et artefacts.
- Configuration des branch protection rules sur GitHub.

## 6. Risques et Impacts

- Une évolution incompatible de Neovim stable peut faire échouer le workflow ;
  ce risque est accepté pour tester la version courante supportée.
- Le code d'une pull request est exécuté sur un runner GitHub isolé, sans secret
  et avec `contents: read` uniquement.
- Rollback : suppression du fichier de workflow.

## 7. Approche proposée

Ajouter un workflow YAML sous `.github/workflows/` avec un job unique. Installer
Neovim stable via une action dédiée épinglée, checkout le dépôt, puis lancer
`nvim --headless -u NONE -l tests/run.lua`.

## 8. Alternatives considérées

- Installer Neovim via APT : rejeté car la version Ubuntu peut être ancienne.
- Ajouter une matrice stable/nightly : différé pour éviter du bruit et un coût
  sans besoin de compatibilité explicite à ce stade.
- Exécuter aussi sur `push` vers `main` : différé car la demande vise les PR.

## 9. Plan d'implémentation

1. Ajouter le workflow avec permissions minimales, déclenchement sur PR et
   déclenchement manuel.
2. Valider la syntaxe et la commande localement autant que possible.
3. Documenter la limite : le check ne devient obligatoire qu'après activation
   dans les règles de protection GitHub.

## 10. Plan de test

- Vérifier la syntaxe YAML et les clés du workflow.
- Réexécuter localement la commande exacte du job.
- Après push, ouvrir ou mettre à jour une PR pour confirmer le check réel.

## 11. Critères d'acceptation

- AC-1 : toute pull request déclenche un job de tests Lua.
- AC-1b : le même job peut être lancé manuellement via GitHub Actions, sans
  paramètre obligatoire.
- AC-2 : le job checkout le commit de la PR et utilise Neovim stable.
- AC-3 : le job échoue lorsque `tests/run.lua` échoue et réussit sinon.
- AC-4 : le workflow n'accorde que la permission `contents: read`.
- AC-5 : un nouveau commit sur une PR annule son run précédent encore actif.
