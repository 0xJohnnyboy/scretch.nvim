# Spec: Variables dynamiques dans les templates Scretch (v1)

## 1. Meta
- Date: 2026-05-27
- Repo: `scretch.nvim`
- Statut: Draft (en attente de `SPEC APPROVED`)
- Auteur spec: Codex

## 2. Contexte / Problème
Le plugin permet déjà de sauvegarder des templates puis de créer une note via `new_from_template()`.
Aujourd'hui, les templates sont statiques. L'utilisateur veut injecter des valeurs dynamiques (date, titre, auteur, variables personnalisées) au moment de la création de note, sans complexifier excessivement la configuration.

## 3. Objectifs
- Ajouter un moteur de rendu de variables dans les templates.
- Supporter un format lisible et extensible: `{{ variable | filter:arg }}`.
- Fournir des variables builtin v1: `date`, `title`, `author`.
- Permettre l'ajout de variables custom via configuration.
- Garder une UX robuste: warnings via `vim.notify` en cas d'erreur de rendu, sans casser la création de fichier.

## 4. Non-objectifs
- Ne pas implémenter de config par dossier de template en v1.
- Ne pas exécuter de code arbitraire dans les templates (pas d'eval Lua inline).
- Ne pas modifier `save_as_template()` (seulement le rendu lors de `new_from_template()`).
- Ne pas introduire de dépendances externes.

## 5. Scope
In:
- Parsing des placeholders `{{ ... }}` dans le contenu template.
- Résolution de variables builtin + custom.
- Application de filtres builtin (dont `uppercase`) et parsing d'arguments.
- Configuration globale `template_variables` (nom final à valider à l'implémentation) avec options date/title/author/custom.
- Politique d'erreur: remplacer par chaîne vide + `vim.notify(..., WARN)`.
- Compatibilité backend Telescope + fzf-lua (même rendu avant écriture du nouveau fichier).

Out:
- Configuration locale par template directory.
- Moteur de templates avancé (conditions, boucles, includes).
- Prompt interactif pour variables manquantes.
- API publique séparée de gestion de filtres custom (peut être ajoutée plus tard).

## 6. Risques et Impacts
- Ambiguïté de parsing si syntaxe invalide (`{{ ...` non fermée, filtres mal formés).
- Risque de surprises si variables inconnues: on choisit warning + vide.
- Cohérence auteur: source configurable (shell/git/littérale) pour éviter comportement implicite.
- Régression potentielle faible: uniquement chemin `new_from_template()`, templates existants sans variables restent inchangés.

## 7. Approche proposée
1. Introduire un module interne de rendu (ex: `render_template_vars(lines, ctx)`), appelé juste après lecture du template et avant écriture du fichier cible.
2. Format v1:
   - `{{ variable }}`
   - `{{ variable | filter }}`
   - `{{ variable | filter:arg1:arg2 }}`
   - espaces tolérés autour des blocs.
3. Variables builtin:
   - `title`: nom du fichier cible sans extension.
   - `date`: date courante locale, format par défaut configurable.
   - `author`: résolue selon stratégie config:
     - `source = "shell"` -> `$USER`
     - `source = "git"` -> `git config user.name`
     - `source = "literal"` -> valeur statique `value`
4. Filtres builtin v1:
   - `uppercase`
   - `lowercase`
   - `trim`
   - `format` (appliqué sur `date` principalement, ex `format:YYYY/MM/dd`)
5. Gestion d'erreurs:
   - Variable inconnue, désactivée, filtre inconnu, ou erreur d'argument -> remplacement `""` + `vim.notify` niveau WARN.
6. Extensibilité:
   - `template_variables.custom = { myvar = function(ctx) return "..." end }`
   - `ctx` inclut au minimum: `new_file_path`, `new_file_name`, `title`, `template_path`, `cwd`, `now`.
7. Config globale simple (pas de config par dossier en v1), forme cible:
   - `template_variables.enabled` (bool, défaut `true`)
   - `template_variables.date = { enabled=true, default_format="YYYY-MM-dd", value="now" }`
   - `template_variables.title = { enabled=true, source="filename" }`
   - `template_variables.author = { enabled=true, source="shell|git|literal", value="" }`
   - `template_variables.custom = { ... }`

## 8. Alternatives considérées
- Config par dossier de templates:
  - Pro: granularité.
  - Con: complexité forte (priorité, lookup, doc, debug).
  - Décision: reportée hors v1.
- Erreur bloquante au lieu de fallback vide:
  - Pro: stricte.
  - Con: UX cassée pour création de note.
  - Décision: warning + vide.
- Syntaxe alternative (`${var}`):
  - Pro: parsing plus simple.
  - Con: moins expressive pour filtres.
  - Décision: garder `{{ ... }}`.

## 9. Plan d'implémentation
1. Étendre la config par défaut avec `template_variables`.
2. Ajouter fonctions utilitaires:
   - parse placeholder
   - resolve builtin/custom vars
   - apply filters
   - notify warning contextualisé
3. Intégrer rendu dans les 2 chemins `new_from_template()` (Telescope/fzf-lua).
4. Mettre à jour `README.md` (section config + exemples template).
5. Mettre à jour `doc/scretch.txt` (help vimdoc).
6. Vérifier manuellement création de note depuis template avec cas nominal + erreurs.

## 10. Plan de test
- Test manuel nominal:
  - Template avec `{{ title }}`, `{{ date }}`, `{{ author }}`.
  - Résultat attendu injecté dans nouveau fichier.
- Test filtres:
  - `{{ title | uppercase }}`
  - `{{ date | format:YYYY/MM/dd }}`
- Test erreur:
  - `{{ unknown }}` -> vide + warning.
  - `{{ title | badfilter }}` -> vide + warning.
- Test stratégie auteur:
  - `shell`, `git`, `literal`.
- Test compat:
  - Template sans variables => rendu inchangé.
  - Fonctionne sur backend Telescope et fzf-lua.

## 11. Critères d'acceptation
- AC-1: Un template contenant `{{ title }}` est rendu avec le nom du nouveau fichier sans extension.
- AC-2: Un template contenant `{{ date }}` est rendu avec la date courante selon `default_format`.
- AC-3: `{{ date | format:YYYY/MM/dd }}` surcharge le format par défaut pour ce placeholder.
- AC-4: `{{ title | uppercase }}` applique bien le filtre uppercase.
- AC-5: `author` respecte la stratégie configurée (`shell`, `git`, `literal`).
- AC-6: Une variable inconnue ou un filtre invalide n'interrompt pas la création du fichier, remplace par vide, et émet un warning via `vim.notify`.
- AC-7: L'API `template_variables.custom` permet d'ajouter une variable custom fonctionnelle.
- AC-8: Les templates existants sans placeholders continuent de produire le même contenu.
- AC-9: Le rendu de variables n'est exécuté que dans `new_from_template()`.
