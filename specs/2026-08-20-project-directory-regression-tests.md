# Spec: Tests de non-régression des répertoires projet

## 1. Meta

- Date : 2026-08-20
- Statut : Approved
- Portée : tests Lua du module `scretch`

## 2. Contexte / Problème

La PR #11 corrige une lecture invalide de `config.use_project.dir` en
`config.use_project_dir`. Les tests existants ne couvraient pas les branches où
les répertoires projet sont activés, ce qui a laissé passer la régression.

## 3. Objectifs

- Protéger le choix du répertoire projet pour les scratchs et les templates.
- Protéger le comportement de `auto_create_project_dir`.
- Vérifier le comportement via l'API publique du module.

## 4. Non-objectifs

- Modifier le comportement ou la configuration du plugin.
- Tester les modes temporaires déjà couverts par d'autres tests.
- Ajouter une nouvelle infrastructure de test ou de CI.

## 5. Scope

### In

- Tests unitaires pour `use_project_dir.scretch = true`.
- Tests unitaires pour `use_project_dir.template = true`.
- Cas `auto_create_project_dir = true` et `false`.

### Out

- Modes `auto`, `global` et commandes interactives.
- Accès réel au système de fichiers.

## 6. Risques et Impacts

- Risque faible de couplage aux détails internes, limité en observant les
  commandes et appels simulés produits par l'API publique.
- Aucun impact sur les données, la sécurité ou les performances de production.
- Rollback : retrait des seuls cas de test ajoutés.

## 7. Approche proposée

Étendre le harnais existant pour exposer son répertoire de travail et les
dossiers créés, puis appeler `setup` avec les configurations projet. Déclencher
une opération publique qui consomme chaque répertoire et vérifier que le chemin
utilisé est construit à partir du répertoire de travail courant et du chemin
relatif configuré, ainsi que la création conditionnelle du dossier.

## 8. Alternatives considérées

- Tester directement les fonctions internes : rejeté car plus couplé à
  l'implémentation.
- Utiliser de vrais dossiers temporaires : rejeté car le harnais simule déjà le
  système de fichiers de façon déterministe.

## 9. Plan d'implémentation

1. Exposer le répertoire de travail simulé et `created_dirs` dans le contexte
   de test.
2. Ajouter les cas scratch et template avec création activée.
3. Ajouter la vérification que la création reste désactivée par défaut.

## 10. Plan de test

- Exécuter `nvim --headless -u NONE -l tests/run.lua`.
- Vérifier que la suite échouerait si le chemin de configuration fautif était
  réintroduit.

## 11. Critères d'acceptation

- AC-1 : un scratch en mode projet utilise, sans erreur, le chemin relatif
  `scretch_project_dir` résolu depuis le répertoire de travail courant.
- AC-2 : un template en mode projet utilise, sans erreur, le chemin relatif
  `template_project_dir` résolu depuis le répertoire de travail courant.
- AC-3 : avec `auto_create_project_dir = true`, le répertoire choisi est créé.
- AC-4 : avec `auto_create_project_dir = false`, aucun répertoire n'est créé.
- AC-5 : toute la suite de tests existante reste verte.
